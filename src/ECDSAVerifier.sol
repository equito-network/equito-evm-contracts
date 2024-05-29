// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IEquitoVerifier} from "./interfaces/IEquitoVerifier.sol";
import {EquitoMessage, EquitoMessageLibrary} from "./libraries/EquitoMessageLibrary.sol";

/// @title ECDSAVerifier
/// @notice This contract is part of the Equito Protocol and verifies that a set of `EquitoMessage` instances
///         have been signed by a sufficient number of Validators, as determined by the threshold.
/// @dev Uses ECDSA for signature verification, adhering to the Ethereum standard.
contract ECDSAVerifier is IEquitoVerifier {
    /// @notice The list of validator addresses.
    address[] public validators;
    /// @notice The threshold percentage of validator signatures required for verification.
    uint256 public immutable threshold = 70;
    /// @notice The current session identifier for the validator set.
    uint256 public session;

    /// @notice Emitted when the validator set is updated.
    event ValidatorSetUpdated();

    /// @notice Initializes the contract with the initial validator set and session identifier.
    /// @param _validators The initial list of validator addresses.
    /// @param _session The initial session identifier.
    constructor(address[] memory _validators, uint256 _session) {
        validators = _validators;
        session = _session;
    }

    /// @notice Verifies that a set of `EquitoMessage` instances have been signed by a sufficient number of Validators.
    /// @param messages The array of `EquitoMessage` instances to verify.
    /// @param proof The concatenated ECDSA signatures from the validators.
    /// @return True if the messages are verified successfully, otherwise false.
    function verifyMessages(
        EquitoMessage[] calldata messages,
        bytes calldata proof
    ) external view override returns (bool) {
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

    /// @notice Updates the list of Validators.
    /// @param _validators The new list of validator addresses.
    /// @param proof The concatenated ECDSA signatures from the current validators approving the new set.
    function updateValidators(
        address[] calldata _validators,
        bytes calldata proof
    ) external {
        bytes32 hashed = keccak256(abi.encode(session, _validators));
        if (this.verifySignatures(hashed, proof)) {
            validators = _validators;
            session += 1;
            emit ValidatorSetUpdated();
        }
    }

    /// @notice Verifies that a hashed message has been signed by a sufficient number of Validators.
    /// @param hash The hash of the message to verify.
    /// @param proof The concatenated ECDSA signatures from the validators.
    /// @return True if the signatures are verified successfully, otherwise false.
    function verifySignatures(
        bytes32 hash,
        bytes memory proof
    ) external view override returns (bool) {
        if (proof.length % 65 != 0) return false;

        uint256 validatorsLength = validators.length;
        address[] memory signatories = new address[](validatorsLength);

        uint256 c = 0;
        uint256 i = 0;

        bytes32 r;
        bytes32 s;
        uint8 v;
        address signer;

        while (i < proof.length) {
            // The Signature Verification is inspired by OpenZeppelin's ECDSA Verification:
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4032b42694ff6599b17ffde65b2b64d7fc8a38f8/contracts/utils/cryptography/ECDSA.sol#L128-L142

            assembly {
                r := mload(add(proof, add(i, 32)))
                s := mload(add(proof, add(i, 64)))
                v := byte(0, mload(add(proof, add(i, 96))))
            }

            if (
                uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
            ) {
                signer = ecrecover(hash, v, r, s);
                if (contains(validators, signer)) {
                    if (!contains(signatories, signer)) {
                        signatories[c] = signer;
                        c += 1;
                    }
                }
            }

            i += 65;
        }

        return c >= (validatorsLength * threshold) / 100;
    }

    /// @notice Helper function to check if an address is present in an array.
    /// @param array The array of addresses to search.
    /// @param value The address to search for.
    /// @return True if the address is found, otherwise false.
    function contains(
        address[] memory array,
        address value
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }
}
