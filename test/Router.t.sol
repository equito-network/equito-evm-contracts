// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Router, IRouter} from "../src/Router.sol";
import {EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {ECDSAVerifier} from "../src/ECDSAVerifier.sol";

contract RouterTest is Test {
    ECDSAVerifier verifier;
    Router router;
    MockReceiver receiver;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    address[] validators = [alice, bob];

    function setUp() public {
        verifier = new ECDSAVerifier(validators);
        router = new Router(1, address(verifier));
        receiver = new MockReceiver();
    }

    function testSendMessage() public {
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

        bytes32 newMessage = router.sendMessage(abi.encode(receiver), 2, data);

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

        router.routeMessages(messages);
    }

    function testRouteMessagesWithDuplicateMessage() public {
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
            memory messages = new EquitoMessage[](2);
        messages[0] = message;
        messages[1] = message;

        bytes32 newMessage = router.sendMessage(abi.encode(receiver), 2, data);

        router.routeMessages(messages);

        assertEq(router.isDuplicateMessage(newMessage), true);
    }
}
