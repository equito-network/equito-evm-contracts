// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";

/// @title EquitoMessageLibraryTest
/// @dev Test suite for the EquitoMessageLibrary contract
contract EquitoMessageLibraryTest is Test {
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address constant CHARLIE = address(0xC04);

    /// @dev Tests the addressToBytes64 and bytes64ToAddress functions of the EquitoMessageLibrary contract
    function testAddressConversion() public {
        bytes64 memory aliceBytes64 = EquitoMessageLibrary.addressToBytes64(ALICE);
        address aliceAddress = EquitoMessageLibrary.bytes64ToAddress(aliceBytes64);

        bytes64 memory bobBytes64 = EquitoMessageLibrary.addressToBytes64(BOB);
        address bobAddress = EquitoMessageLibrary.bytes64ToAddress(bobBytes64);

        assertEq(aliceAddress, ALICE, "Addresses should match for ALICE");
        assertEq(bobAddress, BOB, "Addresses should match for BOB");
    }
}
