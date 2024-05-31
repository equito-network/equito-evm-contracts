// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

/// @title IEquitoFees
/// @notice Interface for the IEquitoFees contract, used to collect fees.
interface IEquitoFees {
    /// @notice Emitted when a fee is paid.
    /// @param payer The address of the account that paid the fee.
    /// @param amount The amount of the fee paid.
    event FeePaid(address indexed payer, uint256 amount);

    /// @notice Gets the current fee amount.
    /// @return The current fee amount in wei.
    function getFee() external view returns (uint256);

    /// @notice Pays the fee. This function should be called with the fee amount sent as msg.value.
    function payFee(address payer) external payable;
}
