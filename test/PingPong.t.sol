// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {PingPong} from "../src/examples/PingPong.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockRouter} from "./mock/MockRouter.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";

contract PingPongTest is Test {
    MockVerifier verifier;
    MockRouter router;
    PingPong pingPong;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address equitoAddress = address(0x45717569746f);

    event PingSent(address indexed sender, uint256 indexed destinationChainSelector, string message);
    event PongReceived(address indexed sender, uint256 indexed sourceChainSelector, string message);

    function setUp() public {
        vm.prank(OWNER);

        verifier = new MockVerifier();
        router = new MockRouter(1, address(verifier), address(verifier), EquitoMessageLibrary.addressToBytes64(equitoAddress));
        pingPong = new PingPong(address(router));

        uint256[] memory chainIds = new uint256[](2);
        chainIds[0] = 1;
        chainIds[1] = 2;

        bytes64[] memory addresses = new bytes64[](2);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(ALICE);
        addresses[1] = EquitoMessageLibrary.addressToBytes64(BOB);

        pingPong.setPeers(chainIds, addresses);
    }

    function testSendPing() public {
        bytes64 memory receiver = EquitoMessageLibrary.addressToBytes64(BOB);
        uint256 destinationChainSelector = 1;
        string memory message = "Hello, world!";

        vm.expectEmit(true, true, true, true);
        emit PingSent(address(this), destinationChainSelector, message);

        pingPong.sendPing{value: 0}(receiver, destinationChainSelector, message);
    }

    function testReceivePingAndSendPong() public {
        string memory pingMessage = "Ping!";

        bytes memory messageData = abi.encode("ping", pingMessage);
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: keccak256(messageData)
        });

        vm.prank(address(router));
        pingPong.receiveMessage(message, messageData);
    }

    function testReceivePong() public {
        string memory pongMessage = "Pong!";

        bytes memory messageData = abi.encode("pong", pongMessage);
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: keccak256(messageData)
        });

        vm.prank(address(router));

        vm.expectEmit(true, true, true, true);
        emit PongReceived(ALICE, 1, pongMessage);
        pingPong.receiveMessage(message, messageData);
    }

    function testInvalidMessageType() public {
        string memory invalidMessage = "Invalid";

        bytes memory messageData = abi.encode("invalid", invalidMessage);
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: keccak256(messageData)
        });

        vm.prank(address(router));

        vm.expectRevert(PingPong.InvalidMessageType.selector);
        pingPong.receiveMessage(message, messageData);
    }

    function testPingPongFlow() public {
        // Step 1: Send Ping
        bytes64 memory receiver = EquitoMessageLibrary.addressToBytes64(BOB);
        uint256 destinationChainSelector = 1;
        string memory pingMessage = "Ping from Alice to Bob";

        vm.prank(ALICE);
        vm.expectEmit(true, true, true, true);
        emit PingSent(ALICE, destinationChainSelector, pingMessage);
        pingPong.sendPing{value: 0}(receiver, destinationChainSelector, pingMessage);

        // Step 2: Simulate receiving the Ping and sending Pong
        bytes memory pingMessageData = abi.encode("ping", pingMessage);
        EquitoMessage memory message1 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: keccak256(pingMessageData)
        });

        vm.prank(address(router));
        pingPong.receiveMessage(message1, pingMessageData);

        // Step 3: Simulate receiving the Pong
        string memory pongMessage = "Pong from Bob to Alice";
        bytes memory pongMessageData = abi.encode("pong", pongMessage);
        EquitoMessage memory message2 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(BOB),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(ALICE),
            hashedData: keccak256(pongMessageData)
        });

        vm.prank(address(router));
        vm.expectEmit(true, true, true, true);
        emit PongReceived(BOB, 2, pongMessage);
        pingPong.receiveMessage(message2, pongMessageData);
    }
}
