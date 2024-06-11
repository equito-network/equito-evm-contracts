// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {PingPong} from "../src/examples/PingPong.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockRouter} from "./mock/MockRouter.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract PingPongTest is Test {
    MockVerifier verifier;
    MockRouter router;
    PingPong pingPong;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address equitoAddress = address(0x45717569746f);
    address peer1 = address(0x506565722031);
    address peer2 = address(0x506565722032);

    event PingSent(uint256 indexed destinationChainSelector, bytes32 messageHash);
    event PingReceived(uint256 indexed sourceChainSelector, bytes32 messageHash);
    event PongReceived(uint256 indexed sourceChainSelector, bytes32 messageHash);

    function setUp() public {
        vm.prank(OWNER);

        verifier = new MockVerifier();
        router = new MockRouter(1, address(verifier), address(verifier), EquitoMessageLibrary.addressToBytes64(equitoAddress));
        pingPong = new PingPong(address(router));

        uint256[] memory chainIds = new uint256[](2);
        chainIds[0] = 1;
        chainIds[1] = 2;

        bytes64[] memory addresses = new bytes64[](2);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(peer1);
        addresses[1] = EquitoMessageLibrary.addressToBytes64(peer2);

        pingPong.setPeers(chainIds, addresses);
    }

   function testSendPing() public {
        uint256 destinationChainSelector = 2;
        string memory pingMessage = "Ping!";
        bytes memory messageData = abi.encode("ping", pingMessage);

        vm.prank(address(router));
        vm.expectEmit(true, true, true, true);
        emit PingSent(destinationChainSelector, keccak256(abi.encode(EquitoMessageLibrary.addressToBytes64(peer2), destinationChainSelector, messageData)));
        pingPong.sendPing{value: 0}(destinationChainSelector, pingMessage);
    }

   function testReceivePingAndSendPong() public {
        uint256 destinationChainSelector = 2;
        string memory pingMessage = "Ping!";
        bytes memory messageData = abi.encode("ping", pingMessage);
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(peer1),
            destinationChainSelector: destinationChainSelector,
            receiver: EquitoMessageLibrary.addressToBytes64(peer2),
            hashedData: keccak256(messageData)
        });

        vm.prank(address(router));
        vm.expectEmit(true, true, true, true);
        emit PingReceived(1, keccak256(abi.encode(message)));
        pingPong.receiveMessage(message, messageData);
    }

    function testReceivePong() public {
        string memory pongMessage = "Pong!";

        bytes memory messageData = abi.encode("pong", pongMessage);
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(peer1),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(peer2),
            hashedData: keccak256(messageData)
        });

        vm.prank(address(router));

        vm.expectEmit(true, true, true, true);
        emit PongReceived(1, keccak256(abi.encode(message)));
        pingPong.receiveMessage(message, messageData);
    }

    function testInvalidMessageType() public {
        string memory invalidMessage = "Invalid";

        bytes memory messageData = abi.encode("invalid", invalidMessage);
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(peer1),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(peer2),
            hashedData: keccak256(messageData)
        });

        vm.prank(address(router));

        vm.expectRevert(PingPong.InvalidMessageType.selector);
        pingPong.receiveMessage(message, messageData);
    }

    function testInvalidPeer() public {
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

        vm.expectRevert(Errors.InvalidMessageSender.selector);
        pingPong.receiveMessage(message, messageData);
    }

    function testPingPongFlow() public {
        // Step 1: Send Ping
        uint256 destinationChainSelector = 2;
        string memory pingMessage = "Ping from Peer 1 to Peer 2";
        bytes memory pingMessageData = abi.encode("ping", pingMessage);
        EquitoMessage memory message1 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(peer1),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(peer2),
            hashedData: keccak256(pingMessageData)
        });

        vm.prank(address(router));
        vm.expectEmit(true, true, true, true);
        emit PingSent(destinationChainSelector, keccak256(abi.encode(EquitoMessageLibrary.addressToBytes64(peer2), destinationChainSelector, pingMessageData)));
        pingPong.sendPing{value: 0}(destinationChainSelector, pingMessage);

        // Step 2: Simulate receiving the Ping and sending Pong
        vm.prank(address(router));
        vm.expectEmit(true, true, true, true);
        emit PingReceived(1, keccak256(abi.encode(message1)));
        pingPong.receiveMessage(message1, pingMessageData);

        // Step 3: Simulate receiving the Pong
        string memory pongMessage = "Pong from Peer 2 to Peer 1";
        bytes memory pongMessageData = abi.encode("pong", pongMessage);
        EquitoMessage memory message2 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(peer2),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(peer1),
            hashedData: keccak256(pongMessageData)
        });

        vm.prank(address(router));

        vm.expectEmit(true, true, true, true);
        emit PongReceived(2, keccak256(abi.encode(message2)));
        pingPong.receiveMessage(message2, pongMessageData);
    }
}
