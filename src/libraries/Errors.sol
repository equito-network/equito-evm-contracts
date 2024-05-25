// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

/// @title Errors
/// @notice Defines all error messages used in the EquitoApp contracts.
library Errors {
    /// @notice Thrown when the router address is invalid.
    /// @param router The address of the router that caused the error.
    error InvalidRouter(address router);

    /// @notice Thrown when the router address is zero.
    error RouterAddressCannotBeZero();

    /// @notice Thrown when the proof for verifying messages is invalid.
    error InvalidMessagesProof();

    /// @notice Thrown when the proof for adding a new verifier is invalid.
    /// @param verifier The address of the verifier that failed to be added.
    error InvalidNewVerifierProof(address verifier);

    /// @notice Thrown when the verifier index provided is out of bounds.
    error InvalidVerifierIndex();

    /// @notice Thrown when the initial verifier address provided in the constructor is zero.
    error InitialVerifierZeroAddress();

    /// @notice Thrown when a verifier address provided is zero.
    error VerifierZeroAddress();

    /// @notice Thrown when the lengths of arrays are invalid.
    error InvalidLength();

    /// @notice Thrown when the sender of a message is invalid.
    error InvalidSender();

    /// @notice Thrown when the sender of a message is invalid.
    error InvalidMessageSender();
}