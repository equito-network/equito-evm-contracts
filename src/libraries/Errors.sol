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

    /// @notice Thrown when a message was not delivered for execution.
    error MessageNotDeliveredForExecution();

    /// @notice Thrown when the sender of a message is invalid.
    error InvalidMessageSender();

    /// @notice Thrown when the network is unsupported.
    error UnsupportedNetwork();

    /// @notice Thrown when the provided fee is insufficient to cover the required cost.
    error InsufficientFee();

    /// @notice Thrown when the amount of ether sent with the transaction is insufficient.
    error InsufficientValueSent();

    /// @notice Thrown when an invalid address is provided, such as the zero address.
    error InvalidAddress();

    /// @notice Thrown when the provided cost is not greater than zero.
    error CostMustBeGreaterThanZero();

    /// @notice Thrown when the token price retrieved from the oracle is invalid or zero.
    error InvalidTokenPriceFromOracle();

    /// @notice Thrown when a message is received from an invalid sovereign account.
    error InvalidSovereign();

    /// @notice Thrown when an invalid operation code is encountered in the received message.
    error InvalidOperation();

    /// @notice Thrown when an invalid liquidity provider address is provided.
    error InvalidLiquidityProvider();

    /// @notice Thrown when a transfer of fees to the liquidity provider fails.
    error TransferFailed();

    /// @notice Thrown when an invalid equito address is provided, such as the zero bytes address.
    error InvalidEquitoAddress();

    /// @notice Thrown when there is a mismatch in session IDs during validation.
    error SessionIdMismatch();
}