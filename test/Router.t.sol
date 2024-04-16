// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Router, IRouter} from "../src/Router.sol";
import {EquitoMessage} from "../src/libraries/EquitoMessage.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";

contract RouterTest is Test {
    Router router;
    MockReceiver receiver;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        router = new Router(1);
        receiver = new MockReceiver();
    }

    function testSendMessage() public {
        vm.prank(alice);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage.EquitoMessage memory message = EquitoMessage
            .EquitoMessage({
                blockNumber: 1,
                sourceChainSelector: 1,
                sender: abi.encode(alice),
                destinationChainSelector: 2,
                receiver: abi.encode(receiver),
                data: data
            });

        bytes32 newMessage = router.sendMessage(abi.encode(receiver), 2, data);

        assertEq(EquitoMessage._hash(message), newMessage);
    }

    function testRouteMessages() public {
        vm.prank(alice);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage.EquitoMessage memory message = EquitoMessage
            .EquitoMessage({
                blockNumber: 1,
                sourceChainSelector: 1,
                sender: abi.encode(alice),
                destinationChainSelector: 2,
                receiver: abi.encode(receiver),
                data: data
            });

        EquitoMessage.EquitoMessage[]
            memory messages = new EquitoMessage.EquitoMessage[](1);
        messages[0] = message;

        router.routeMessages(messages);
    }

    function testRouteMessagesWithDuplicateMessage() public {
        vm.prank(alice);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage.EquitoMessage memory message = EquitoMessage
            .EquitoMessage({
                blockNumber: 1,
                sourceChainSelector: 1,
                sender: abi.encode(alice),
                destinationChainSelector: 2,
                receiver: abi.encode(receiver),
                data: data
            });

        EquitoMessage.EquitoMessage[]
            memory messages = new EquitoMessage.EquitoMessage[](2);
        messages[0] = message;
        messages[1] = message;

        bytes32 newMessage = router.sendMessage(abi.encode(receiver), 2, data);

        router.routeMessages(messages);

        assertEq(router.isDuplicateMessage(newMessage), true);
    }
}
