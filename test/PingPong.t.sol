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

    address sender = address(0xa0);
    address equitoAddress = address(0xe0);
    address peer1 = address(0x01);
    address peer2 = address(0x02);

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
    event MessageSendRequested(
        EquitoMessage message,
        bytes messageData
    );

    function setUp() public {
        vm.prank(sender);

        verifier = new MockVerifier();
        fees = new MockEquitoFees();
        router = new Router(
            0,
            address(verifier),
            address(fees),
            EquitoMessageLibrary.addressToBytes64(equitoAddress)
        );
        pingPong = new PingPong(address(router));

        uint256[] memory chainSelectors = new uint256[](2);
        chainSelectors[0] = 1;
        chainSelectors[1] = 2;

        bytes64[] memory addresses = new bytes64[](2);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(peer1);
        addresses[1] = EquitoMessageLibrary.addressToBytes64(peer2);

        pingPong.setPeers(chainSelectors, addresses);

        vm.deal(address(sender), 10 ether);
    }

    function testSendPing() public {
        uint256 destinationChainSelector = 2;
        string memory pingMessage = "Ping!";
        bytes memory messageData = abi.encode("ping", pingMessage);

        uint256 fee = router.getFee(address(pingPong));

        vm.prank(sender);
        vm.expectEmit(true, true, true, true);
        emit PingSent(
            destinationChainSelector,
            keccak256(
                abi.encode(
                    EquitoMessage({
                        blockNumber: 1,
                        sourceChainSelector: 0,
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
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(address(pingPong)),
            hashedData: keccak256(messageData)
        });

        uint256 feeContractBalance = address(fees).balance;
        uint256 fee = router.getFee(address(pingPong));

        vm.expectEmit(address(pingPong));
        emit PingReceived(2, keccak256(abi.encode(message)));

        vm.expectEmit(address(router));
        emit MessageSendRequested(
            EquitoMessage({
                blockNumber: 1,
                sourceChainSelector: 0,
                sender: EquitoMessageLibrary.addressToBytes64(
                    address(pingPong)
                ),
                destinationChainSelector: 2,
                receiver: EquitoMessageLibrary.addressToBytes64(peer2),
                hashedData: keccak256(abi.encode("pong", pingMessage))
            }),
            abi.encode("pong", pingMessage)
        );

        vm.prank(address(sender));
        router.deliverAndExecuteMessage{value: fee}(
            message,
            messageData,
            0,
            abi.encode(1)
        );

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

    function testInvalidSender() public {
        string memory pongMessage = "message";

        bytes memory messageData = abi.encode("pong", pongMessage);
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(address(0x00)),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(address(pingPong)),
            hashedData: keccak256(messageData)
        });

        vm.prank(address(router));

        vm.expectRevert(Errors.InvalidMessageSender.selector);
        pingPong.receiveMessage(message, messageData);
    }
}
