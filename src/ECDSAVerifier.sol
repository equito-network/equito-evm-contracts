// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IEquitoVerifier} from "./interfaces/IEquitoVerifier.sol";
import {EquitoMessage} from "./libraries/EquitoMessageLibrary.sol";

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

    /// Verify that a set of EquitoMessage has been signed by a sufficient number of Validators, determined by the threshold.
    function verifyMessages(
        EquitoMessage[] calldata messages,
        bytes calldata proof
    ) external override returns (bool) {
        if (messages.length == 0) return false;

        bytes32 hashed;
        if (messages.length == 1) {
            hashed = EquitoMessageLibrary._hash(messages[0]);
        } else {
            hashed = keccak256(abi.encode(messages));
        }

        return _verifySignatures(hashed, proof);
    }

    /// Update the list of Validators.
    /// The new set should be signed by a sufficient number of Validators, determined by the threshold.
    function updateValidators(
        address[] calldata _validators, 
        bytes calldata proof
    ) external {
        bytes32 hashed = keccak256(abi.encode(_validators));
        if (_verifySignatures(hashed, proof)) {
            validators = _validators;
            // Emit event
            emit ValidatorSetUpdated();
        } 
    }

    /// Internal function to verify that a certain hashed message has been signed by a sufficient number of Validators,
    /// determined by the threshold, without any assumption on the content of the message itself.
    function _verifySignatures(
        bytes32 hash,
        bytes calldata proof
    ) internal returns (bool) {
        // Decode proof as a list of bytes arrays
        // we know that a well-formed signature has length 65,
        // therefore we can use this to split the proof into signatures 
        // and `return false` if the proof length is not a multiple of 65

        // Recover the addresses of the signers with `hash`
        // and store the ones that are validators in a set
        
        // Count the number of validators that signed the message
        // `return countValidators > totalValidators * threshold / 100`

        return false;
    }
}