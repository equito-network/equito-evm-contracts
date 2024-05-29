// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../libraries/EquitoMessageLibrary.sol";

/// @title IEquitoVerifier
/// @notice Interface for the verifier contract used in the Equito protocol to verify cross-chain messages.
interface IEquitoVerifier {
    /// @notice Verifies a set of Equito messages using the provided proof.
    /// @param messages The array of Equito messages to verify.
    /// @param proof The proof provided to verify the messages.
    /// @return True if the messages are verified successfully, otherwise false.
    function verifyMessages(
        EquitoMessage[] calldata messages,
        bytes calldata proof
    ) external returns (bool); 

    /// @notice Verifies the signatures of a hashed message using the provided proof.
    /// @param hash The hash of the message to verify.
    /// @param proof The proof provided to verify the signatures.
    /// @return True if the signatures are verified successfully, otherwise false.
    function verifySignatures(
        bytes32 hash,
        bytes calldata proof
    ) external returns (bool);
}