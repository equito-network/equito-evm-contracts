// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Router, IRouter} from "../src/Router.sol";
import {EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";

contract RouterTest is Test {
    MockVerifier verifier;
    Router router;
    MockReceiver receiver;

    address alice = address(0xA11CE);

    function setUp() public {
        verifier = new MockVerifier();
        router = new Router(1, address(verifier));
        receiver = new MockReceiver();
    }

    function testEncodeGasEstimation() public {
        abi.encode("Hello, World!");
    }

    function testEncodePackedGasEstimation() public {
        abi.encodePacked("Hello, World!");
    }

    function testSendMessage() public {
        vm.prank(alice);
        bytes memory data = abi.encodePacked("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encodePacked(alice),
            destinationChainSelector: 2,
            receiver: abi.encodePacked(receiver),
            data: data
        });

        bytes32 newMessage = router.sendMessage(abi.encodePacked(receiver), 2, data);

        assertEq(EquitoMessageLibrary._hash(message), newMessage);
    }

    function testRouteMessages() public {
        vm.prank(alice);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(alice),
            destinationChainSelector: 2,
            receiver: abi.encode(receiver),
            data: data
        });

        EquitoMessage[]
            memory messages = new EquitoMessage[](1);
        messages[0] = message;

        router.routeMessages(messages, 0, abi.encode(1));
    }

    function testRouteMessagesWithDuplicateMessage() public {
        vm.prank(alice);
        bytes memory data1 = abi.encode("Hello, World!");

        EquitoMessage memory message1 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(alice),
            destinationChainSelector: 2,
            receiver: abi.encode(receiver),
            data: data1
        });

        bytes memory data2 = abi.encode("This is a test!");

        EquitoMessage memory message2 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(alice),
            destinationChainSelector: 2,
            receiver: abi.encode(receiver),
            data: data2
        });

        EquitoMessage[]
            memory messages = new EquitoMessage[](3);
        messages[0] = message1;
        messages[1] = message2;
        messages[2] = message1;

        bytes32 message1Hash = EquitoMessageLibrary._hash(message1);
        bytes32 message2Hash = EquitoMessageLibrary._hash(message2);

        router.routeMessages(messages, 0, abi.encode(1));

        assertEq(router.isDuplicateMessage(message1Hash), true);
        assertEq(router.isDuplicateMessage(message2Hash), true);

        assertEq(receiver.getMessage().data, message2.data);
    }
}
