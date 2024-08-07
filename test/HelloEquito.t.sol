// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {HelloEquito} from "../src/examples/HelloEquito.sol";
import {MockRouter} from "./mock/MockRouter.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract HelloEquitoTest is Test {
    MockRouter router;
    HelloEquito helloEquito;

    address sender = address(0xa0);
    address equitoAddress = address(0xe0);
    address peer = address(0xbb);

    event HelloMessageSent(
        uint256 indexed destinationChainSelector,
        bytes32 messageHash
    );

    event HelloMessageReceived(
        uint256 indexed sourceChainSelector,
        bytes32 messageHash,
        bytes messageData
    );

    event MessageSendRequested(EquitoMessage message, bytes messageData);

    event MessageExecuted(bytes32 messageHash);

    function setUp() public {
        vm.prank(sender);

        router = new MockRouter(
            1,
            EquitoMessageLibrary.addressToBytes64(equitoAddress)
        );
        helloEquito = new HelloEquito(address(router));

        uint256[] memory chainSelectors = new uint256[](2);
        chainSelectors[0] = 1;
        chainSelectors[1] = 2;

        bytes64[] memory addresses = new bytes64[](2);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(
            address(helloEquito)
        );
        addresses[1] = EquitoMessageLibrary.addressToBytes64(peer);

        helloEquito.setPeers(chainSelectors, addresses);
    }

    function testSendMessage() public {
        vm.prank(sender);

        // MockRouter generates a dummy hash based on the input parameters only
        bytes32 expectedHash = keccak256(
            abi.encode(
                EquitoMessageLibrary.addressToBytes64(peer),
                2,
                abi.encode("Hello, Equito!")
            )
        );

        vm.expectEmit(true, true, false, true);
        emit HelloMessageSent(2, expectedHash);

        helloEquito.sendMessage(2);
    }

    function testSendMessageInvalidPeer() public {
        vm.prank(sender);

        vm.expectRevert();

        helloEquito.sendMessage(3);
    }

    function testReceiveMessageFromPeer() public {
        bytes memory messageData = abi.encode("Hello, Equito!");
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(peer),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(
                address(helloEquito)
            ),
            hashedData: keccak256(messageData)
        });

        vm.expectEmit(true, true, false, true);
        emit HelloMessageReceived(
            message.sourceChainSelector,
            keccak256(abi.encode(message)),
            messageData
        );

        vm.prank(address(router));
        helloEquito.receiveMessage(message, messageData);
    }

    function testReceiveMessageFromNonPeerSender() public {
        bytes memory messageData = abi.encode("Hello, Equito!");
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(address(0xaa)),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(
                address(helloEquito)
            ),
            hashedData: keccak256(messageData)
        });

        vm.expectRevert(Errors.InvalidMessageSender.selector);

        vm.prank(address(router));
        helloEquito.receiveMessage(message, messageData);
    }

    function testReceiveMessageFromNonPeerChain() public {
        bytes memory messageData = abi.encode("Hello, Equito!");
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 3,
            sender: EquitoMessageLibrary.addressToBytes64(peer),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(
                address(helloEquito)
            ),
            hashedData: keccak256(messageData)
        });

        vm.expectRevert(Errors.InvalidMessageSender.selector);

        vm.prank(address(router));
        helloEquito.receiveMessage(message, messageData);
    }
}
