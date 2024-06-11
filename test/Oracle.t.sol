// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {MockOracle} from "./mock/MockOracle.sol";
import {Errors} from "../src/libraries/Errors.sol";

/// @title OracleTest
/// @dev Test suite for the Oracle contract
contract OracleTest is Test {
    MockOracle oracle;

    function setUp() public {
        oracle = new MockOracle(100);
    }
    
    /// @notice Tests the retrieval of the token price in USD from the Oracle contract.
    function testGetTokenPriceUsd() public {
        uint256 tokenPriceUsd = oracle.getTokenPriceUsd();
        assertEq(tokenPriceUsd, 100, "Incorrect token price returned");
    }
}