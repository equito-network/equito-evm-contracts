// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";

/// @title EquitoMessageLibraryTest
/// @dev Test suite for the EquitoMessageLibrary contract
contract EquitoMessageLibraryTest is Test {
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);

    /// @dev Tests the _hash function of the EquitoMessageLibrary contract
    function testHash() public {
        EquitoMessage memory message1 = EquitoMessage({
            blockNumber: 123,
            sourceChainSelector: 1,
            sender: abi.encode(ALICE),
            destinationChainSelector: 2,
            receiver: abi.encode(BOB),
            data: abi.encode("Message 1 data")
        });

        EquitoMessage memory message2 = EquitoMessage({
            blockNumber: 456,
            sourceChainSelector: 3,
            sender: abi.encode(BOB),
            destinationChainSelector: 4,
            receiver: abi.encode(ALICE),
            data: abi.encode("Message 2 data")
        });

        bytes32 hash1 = EquitoMessageLibrary._hash(message1);
        bytes32 hash2 = EquitoMessageLibrary._hash(message2);

        bytes32 expectedHash1 = keccak256(
            abi.encodePacked(
                keccak256(
                    abi.encodePacked(
                        message1.blockNumber,
                        message1.sourceChainSelector,
                        message1.destinationChainSelector
                    )
                ),
                keccak256(message1.sender),
                keccak256(message1.receiver),
                keccak256(message1.data)
            )
        );

        bytes32 expectedHash2 = keccak256(
            abi.encodePacked(
                keccak256(
                    abi.encodePacked(
                        message2.blockNumber,
                        message2.sourceChainSelector,
                        message2.destinationChainSelector
                    )
                ),
                keccak256(message2.sender),
                keccak256(message2.receiver),
                keccak256(message2.data)
            )
        );

        assertEq(hash1, expectedHash1, "Hashes should match for message 1");
        assertEq(hash2, expectedHash2, "Hashes should match for message 2");
    }
}