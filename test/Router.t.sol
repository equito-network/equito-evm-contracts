// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Router, IRouter} from "../src/Router.sol";
import {EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {IEquitoVerifier} from "../src/interfaces/IEquitoVerifier.sol";
import {Errors} from "../src/libraries/Errors.sol";

/// @title RouterTest
/// @dev Test suite for the Router contract
contract RouterTest is Test {
    MockVerifier verifier;
    Router router;
    MockReceiver receiver;

    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);

    event MessageSendRequested(address indexed sender, EquitoMessage message);
    event VerifierAdded(address indexed verifier);

    function setUp() public {
        verifier = new MockVerifier();
        router = new Router(1, address(verifier));
        receiver = new MockReceiver();
    }

    /// @dev Tests the constructor of the Router contract
    function testConstructor() public {
        assertEq(router.chainSelector(), 1, "Chain selector not initialized correctly");
    }

    /// @dev Tests the sendMessage function of the Router contract
    function testSendMessage() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(ALICE),
            destinationChainSelector: 2,
            receiver: abi.encode(receiver),
            data: data
        });

        vm.expectEmit(true, true, true, true);
        emit MessageSendRequested(address(ALICE), message);

        bytes32 messageHash = router.sendMessage(abi.encode(receiver), 2, data);

        assertEq(EquitoMessageLibrary._hash(message), messageHash);
    }

    /// @dev Tests routing of messages with a single message successfully
    function testRouteMessagesSuccess() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(ALICE),
            destinationChainSelector: 2,
            receiver: abi.encode(receiver),
            data: data
        });

        EquitoMessage[]
            memory messages = new EquitoMessage[](1);
        messages[0] = message;

        router.routeMessages(messages, 0, abi.encode(1));
        assertTrue(router.isDuplicateMessage(EquitoMessageLibrary._hash(messages[0])), "Message not delivered");
    }

    /// @dev Tests routing of messages with an invalid verifier index
    function testRouteMessagesInvalidVerifierIndex() public {
        bytes memory proof = abi.encode("proof");
        uint256 invalidVerifierIndex = 1;
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(ALICE),
            destinationChainSelector: 2,
            receiver: abi.encode(receiver),
            data: data
        });

        EquitoMessage[]
            memory messages = new EquitoMessage[](1);
        messages[0] = message;

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidVerifierIndex.selector));
        router.routeMessages(messages, invalidVerifierIndex, proof);
    }

    /// @dev Tests routing of messages with an invalid proof
    function testRouteMessagesInvalidProof() public {
        bytes memory invalidProof = "";
        uint256 verifierIndex = 0;

        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(ALICE),
            destinationChainSelector: 2,
            receiver: abi.encode(receiver),
            data: data
        });

        EquitoMessage[]
            memory messages = new EquitoMessage[](1);
        messages[0] = message;

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidMessagesProof.selector));
        router.routeMessages(messages, verifierIndex, invalidProof);
    }

    /// @dev Tests routing of messages with duplicate messages
    function testRouteMessagesWithDuplicateMessage() public {
        vm.prank(ALICE);
        bytes memory data1 = abi.encode("Hello, World!");

        EquitoMessage memory message1 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(ALICE),
            destinationChainSelector: 2,
            receiver: abi.encode(receiver),
            data: data1
        });

        bytes memory data2 = abi.encode("This is a test!");

        EquitoMessage memory message2 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(ALICE),
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

        assertTrue(router.isDuplicateMessage(message1Hash), "Message not delivered");
        assertTrue(router.isDuplicateMessage(message2Hash), "Message not delivered");

        assertEq(receiver.getMessage().data, message2.data);
    }

    /// @dev Tests adding a verifier to the Router contract successfully
    function testAddVerifierSuccess() public {
        vm.prank(BOB);
        bytes memory proof = abi.encode("proof");

        vm.expectEmit(true, true, true, true);
        emit VerifierAdded(BOB);

        router.addVerifier(BOB, 0, proof);

        assertEq(address(router.verifiers(1)), BOB, "The new verifier should be BOB");
    }

    /// @dev Tests adding a verifier with an invalid verifier index
    function testAddVerifierInvalidVerifierIndex() public {
        bytes memory proof = abi.encode("proof");
        uint256 invalidVerifierIndex = 1;

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidVerifierIndex.selector));
        router.addVerifier(address(verifier), invalidVerifierIndex, proof);
    }

    /// @dev Tests adding a verifier with an invalid proof
    function testAddVerifierInvalidProof() public {
        uint256 verifierIndex = 0;
        bytes memory invalidProof = "";

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidNewVerifierProof.selector, address(verifier)));
        router.addVerifier(address(verifier), verifierIndex, invalidProof);
    }
}
