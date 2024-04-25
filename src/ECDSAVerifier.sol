// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IEquitoVerifier} from "./interfaces/IEquitoVerifier.sol";
import {EquitoMessage, EquitoMessageLibrary} from "./libraries/EquitoMessageLibrary.sol";

/// The ECDSAVerifier contract is used in the Equito Protocol to verify that a set of EquitoMessage
/// has been signed by a sufficient number of Validators, determined by the threshold.
/// The Current Validator Set's addresses are stored in the contract, allowing for updates.
/// Signatures are verified using the ECDSA signature scheme, following the Ethereum standard.
contract ECDSAVerifier is IEquitoVerifier {
    address[] public validators;
    uint256 public immutable threshold = 70;

    event ValidatorSetUpdated();

    constructor(address[] memory _validators) {
        validators = _validators;
    }

    /// Verify that a set of EquitoMessage has been signed by a sufficient number of Validators,
    /// determined by the threshold.
    function verifyMessages(
        EquitoMessage[] calldata messages,
        bytes calldata proof
    ) external override returns (bool) {
        if (messages.length == 0) return false;

        bytes32 hashed;
        if (messages.length == 1) {
            hashed = EquitoMessageLibrary._hash(messages[0]);
        } else {
            // TODO: use a more efficient way to hash multiple messages
            hashed = keccak256(abi.encode(messages));
        }

        return this.verifySignatures(hashed, proof);
    }

    /// Update the list of Validators.
    /// The new set should be signed by a sufficient number of Validators, determined by the threshold.
    function updateValidators(
        address[] calldata _validators,
        bytes calldata proof
    ) external {
        bytes32 hashed = keccak256(abi.encode(_validators));
        if (this.verifySignatures(hashed, proof)) {
            validators = _validators;
            // Emit event
            emit ValidatorSetUpdated();
        }
    }

    /// Verify that a certain hashed message has been signed by a sufficient number of Validators,
    /// determined by the threshold, without any assumption on the content of the message itself.
    function verifySignatures(
        bytes32 hash,
        bytes calldata proof
    ) external override returns (bool) {
        if (proof.length % 65 != 0) return false;

        // This doesn't work as mappings are only valid for storage.
        // TODO: Find an alternative solution to avoid counting duplicates.
        mapping(address => bool) signed;

        uint256 i = 0;
        while (i < proof.length) {
            // The Signature Verification is inspired by OpenZeppelin's ECDSA Verification:
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4032b42694ff6599b17ffde65b2b64d7fc8a38f8/contracts/utils/cryptography/ECDSA.sol#L128-L142
            bytes32 r;
            bytes32 s;
            uint8 v;

            assembly {
                r := mload(add(proof, add(i, 32)))
                s := mload(add(proof, add(i, 64)))
                v := byte(0, mload(add(proof, add(i, 96))))
            }

            if (
                uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
            ) {
                address signer = ecrecover(hash, v, r, s);
                if (validators.contains(signer)) {
                    signed[signer] = true;
                }
            }

            i += 65;
        }

        return signed.length > (validators.length * threshold) / 100;
    }
}
