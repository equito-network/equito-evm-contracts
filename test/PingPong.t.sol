// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {PingPong} from "../src/examples/PingPong.sol";
import {Router} from "../src/Router.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockEquitoFees} from "./mock/MockEquitoFees.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract PingPongTest is Test {
    Router router;
    MockVerifier verifier;
    MockEquitoFees fees;
    PingPong pingPong;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address equitoAddress = address(0x45717569746f);
    address peer1 = address(0x506565722031);
    address peer2 = address(0x506565722032);

    event PingSent(
        uint256 indexed destinationChainSelector,
        bytes32 messageHash
    );
    event PingReceived(
        uint256 indexed sourceChainSelector,
        bytes32 messageHash
    );
    event PongReceived(
        uint256 indexed sourceChainSelector,
        bytes32 messageHash
    );

    event MessageSendRequested(EquitoMessage message, bytes messageData);

    function setUp() public {
        vm.prank(OWNER);

        verifier = new MockVerifier();
        fees = new MockEquitoFees();
        router = new Router(
            1,
            address(verifier),
            address(fees),
            EquitoMessageLibrary.addressToBytes64(equitoAddress)
        );
        pingPong = new PingPong(address(router));

        uint256[] memory chainIds = new uint256[](2);
        chainIds[0] = 1;
        chainIds[1] = 2;

        bytes64[] memory addresses = new bytes64[](2);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(peer1);
        addresses[1] = EquitoMessageLibrary.addressToBytes64(peer2);

        pingPong.setPeers(chainIds, addresses);

        vm.deal(address(ALICE), 10 ether);
    }

    function testSendPing() public {
        uint256 destinationChainSelector = 2;
        string memory pingMessage = "Ping!";
        bytes memory messageData = abi.encode("ping", pingMessage);

        uint256 fee = router.getFee(address(pingPong));

        vm.prank(address(ALICE));
        vm.expectEmit(true, true, true, true);
        emit PingSent(
            destinationChainSelector,
            keccak256(
                abi.encode(
                    EquitoMessage({
                        blockNumber: 1,
                        sourceChainSelector: 1,
                        sender: EquitoMessageLibrary.addressToBytes64(
                            address(pingPong)
                        ),
                        destinationChainSelector: destinationChainSelector,
                        receiver: EquitoMessageLibrary.addressToBytes64(peer2),
                        hashedData: keccak256(messageData)
                    })
                )
            )
        );

        pingPong.sendPing{value: fee}(destinationChainSelector, pingMessage);
    }

    function testReceivePingAndSendPong() public {
        string memory pingMessage = "Equito";
        bytes memory messageData = abi.encode("ping", pingMessage);
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(peer2),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(pingPong)),
            hashedData: keccak256(messageData)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;
        router.deliverMessages(messages, 0, abi.encode(1));

        uint256 feeContractBalance = address(fees).balance;

        uint256 fee = router.getFee(address(pingPong));

        vm.expectEmit(address(pingPong));
        emit PingReceived(2, keccak256(abi.encode(message)));

        vm.expectEmit(address(router));
        emit MessageSendRequested(
            EquitoMessage({
                blockNumber: 1,
                sourceChainSelector: 1,
                sender: EquitoMessageLibrary.addressToBytes64(
                    address(pingPong)
                ),
                destinationChainSelector: 2,
                receiver: EquitoMessageLibrary.addressToBytes64(peer2),
                hashedData: keccak256(abi.encode("pong", pingMessage))
            }),
            abi.encode("pong", pingMessage)
        );

        vm.prank(address(ALICE));
        router.executeMessage{value: fee}(message, messageData);

        assertEq(address(fees).balance, feeContractBalance + fee);
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
}
