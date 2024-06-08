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

    /// @dev Tests the _hash function of the EquitoMessageLibrary contract for a single EquitoMessage
    function testHash() public {
        EquitoMessage memory message1 = EquitoMessage({
            blockNumber: 123,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode("Message 1 data")
        });

        EquitoMessage memory message2 = EquitoMessage({
            blockNumber: 456,
            sourceChainSelector: 3,
            sender: EquitoMessageLibrary.addressToBytes64(BOB),
            destinationChainSelector: 4,
            receiver: EquitoMessageLibrary.addressToBytes64(ALICE),
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
                message1.sender.lower,
                message1.sender.upper,
                message1.receiver.lower,
                message1.receiver.upper,
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
                message2.sender.lower,
                message2.sender.upper,
                message2.receiver.lower,
                message2.receiver.upper,
                keccak256(message2.data)
            )
        );

        assertEq(hash1, expectedHash1, "Hashes should match for message 1");
        assertEq(hash2, expectedHash2, "Hashes should match for message 2");
    }

    /// @notice Tests the _hash function of the EquitoMessageLibrary contract for an array of EquitoMessage
    function testHashArray() public {
        EquitoMessage[] memory messages = new EquitoMessage[](5);
        messages[0] = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode("Message #1")
        });
        messages[1] = EquitoMessage({
            blockNumber: 2,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(BOB),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(ALICE),
            data: abi.encode("Message #2")
        });
        messages[2] = EquitoMessage({
            blockNumber: 3,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 3,
            receiver: EquitoMessageLibrary.addressToBytes64(CHARLIE),
            data: abi.encode("Message #3")
        });
        messages[3] = EquitoMessage({
            blockNumber: 4,
            sourceChainSelector: 3,
            sender: EquitoMessageLibrary.addressToBytes64(CHARLIE),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(ALICE),
            data: abi.encode("Message #5")
        });
        messages[4] = EquitoMessage({
            blockNumber: 5,
            sourceChainSelector: 3,
            sender: EquitoMessageLibrary.addressToBytes64(CHARLIE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(ALICE),
            data: abi.encode("Message #5")
        });

        bytes32[] memory hashes = new bytes32[](messages.length);

        for (uint256 i = 0; i < messages.length; ) {
            hashes[i] = EquitoMessageLibrary._hash(messages[i]);
            unchecked { ++i; }
        }

        assertEq(
            keccak256(abi.encodePacked(hashes)),
            EquitoMessageLibrary._hash(messages),
            "Hashed should match for message list"
        );
    }

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
