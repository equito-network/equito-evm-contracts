// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IOracle} from "../../src/interfaces/IOracle.sol";
import {Errors} from "../../src/libraries/Errors.sol";

/// @title MockOracle
/// @notice Mock implementation of the Oracle interface for testing purposes.
contract MockOracle is IOracle {
    /// @notice Retrieves the price of a token in USD.  
    /// @return The price of the token in USD.
    function getTokenPriceUsd() external view returns (uint256) {
        return 100;
    }
}