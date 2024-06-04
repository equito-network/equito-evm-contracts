// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IEquitoFees} from "../../src/interfaces/IEquitoFees.sol";
import {Errors} from "../../src/libraries/Errors.sol";

/// @title MockEquitoFees
/// @notice This mock contract is used for testing purposes, implementing the IEquitoFees interface.
/// @dev This contract provides a fixed fee amount and emits an event when the fee is paid.
contract MockEquitoFees is IEquitoFees {
    /// @dev The current fee amount.
    uint256 constant INITIAL_FEE = 0.1 ether;

    /// @notice Returns the fixed fee amount.
    /// @return The fixed fee amount, which is 0.1 ether.
    function getFee() external view returns (uint256) {
        return INITIAL_FEE;
    }

    /// @notice Allows users to pay the fee. This function should be called with 0.1 ether sent as msg.value.
    /// @param payer The address of the original caller who is paying the fee.
    function payFee(address payer) external payable {
        if (INITIAL_FEE > msg.value) {
            revert Errors.InsufficientFee();
        }

        emit FeePaid(payer, msg.value);
    }
}