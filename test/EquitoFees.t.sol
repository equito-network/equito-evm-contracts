// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockEquitoFees} from "./mock/MockEquitoFees.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {MockRouter} from "./mock/MockRouter.sol";
import {IEquitoVerifier} from "../src/interfaces/IEquitoVerifier.sol";
import {Errors} from "../src/libraries/Errors.sol";

/// @title EquitoFeesTest
/// @dev Test suite for the EquitoFees contract
contract EquitoFeesTest is Test {
    MockRouter router;
    MockEquitoFees equitoFees;

    uint256 constant INITIAL_FEE = 0.1 ether;
    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);

    event FeePaid(address indexed payer, uint256 amount);

    function setUp() public {
        vm.startPrank(OWNER);
        equitoFees = new MockEquitoFees();
        vm.stopPrank();
    }

    /// @notice Test that the initial fee is set correctly.
    function testInitialFee() public {
        uint256 fee = equitoFees.getFee(ALICE);
        assertEq(fee, INITIAL_FEE, "Initial fee should be set correctly");
    }

    /// @notice Test paying the fee with sufficient amount.
    function testPayFeeSuccess() public {
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE);

        vm.expectEmit(true, true, true, true);
        emit FeePaid(ALICE, INITIAL_FEE);
        equitoFees.payFee{value: INITIAL_FEE}(ALICE);
    }

    /// @notice Test paying the fee with insufficient amount.
    function testPayFeeInsufficient() public {
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE);

        vm.expectRevert(Errors.InsufficientFee.selector);
        equitoFees.payFee{value: INITIAL_FEE / 2}(ALICE);
    }
}
