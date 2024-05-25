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
    event MessagesDelivered(EquitoMessage[] messages);
    event MessagesExecuted(EquitoMessage[] messages);

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

    /// @dev Tests delivering and executing of messages with a single message successfully
    function testDeliverAndExecuteMessagesSuccess() public {
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

        router.deliverAndExecuteMessages(messages, 0, abi.encode(1));
        assertTrue(router.isDuplicateMessage(EquitoMessageLibrary._hash(messages[0])), "Message not delivered");
    }

    /// @dev Tests delivering and executing of messages with an invalid verifier index
    function testDeliverAndExecuteMessagesInvalidVerifierIndex() public {
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
        router.deliverAndExecuteMessages(messages, invalidVerifierIndex, proof);
    }

    /// @dev Tests delivering and executing of messages with an invalid proof
    function testDeliverAndExecuteMessagesInvalidProof() public {
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
        router.deliverAndExecuteMessages(messages, verifierIndex, invalidProof);
    }

    /// @dev Tests delivering and executing of messages with duplicate messages
    function testDeliverAndExecuteMessagesWithDuplicateMessage() public {
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

        router.deliverAndExecuteMessages(messages, 0, abi.encode(1));

        assertTrue(router.isDuplicateMessage(message1Hash), "Message not delivered");
        assertTrue(router.isDuplicateMessage(message2Hash), "Message not delivered");

        assertEq(receiver.getMessage().data, message2.data);
    }

    
    
    /// @dev Tests delivering of messages with a single message successfully
    function testDeliverMessagesSuccess() public {
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

        vm.expectEmit(true, true, false, true);
        emit MessagesDelivered(messages);

        router.deliverMessages(messages, 0, abi.encode(1));

        (
            uint256 storedBlockNumber,
            uint256 storedSourceChainSelector,
            bytes memory storedSender,
            uint256 storedDestinationChainSelector,
            bytes memory storedReceiver,
            bytes memory storedData
        ) = router.storedMessages(EquitoMessageLibrary._hash(messages[0]));

        assertEq(storedBlockNumber, message.blockNumber);
        assertEq(storedSourceChainSelector, message.sourceChainSelector);
        assertEq(storedDestinationChainSelector, message.destinationChainSelector);
        assertEq(storedSender, message.sender);
        assertEq(storedReceiver, message.receiver);
        assertEq(storedData, message.data);
    }

    /// @dev Tests delivering and executing of messages with an invalid verifier index
    function testDeliverMessagesInvalidVerifierIndex() public {
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
        router.deliverMessages(messages, invalidVerifierIndex, proof);
    }

    /// @dev Tests delivering and executing of messages with an invalid proof
    function testDeliverMessagesInvalidProof() public {
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
        router.deliverMessages(messages, verifierIndex, invalidProof);
    }

    /// @dev Tests executing of messages with a single message successfully
    function testExecuteMessagesSuccess() public {
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

        bytes32 messageHash = EquitoMessageLibrary._hash(messages[0]);

        router.deliverMessages(messages, 0, abi.encode(1));
        (
            uint256 storedBlockNumber,
            uint256 storedSourceChainSelector,
            bytes memory storedSender,
            uint256 storedDestinationChainSelector,
            bytes memory storedReceiver,
            bytes memory storedData
        ) = router.storedMessages(messageHash);
        assertTrue(storedBlockNumber != 0, "Message not delivered");

        vm.expectEmit(true, true, false, true);
        emit MessagesExecuted(messages);

        router.executeMessages(messages);

        (
            uint256 storedBlockNumber2,
            uint256 storedSourceChainSelector2,
            bytes memory storedSender2,
            uint256 storedDestinationChainSelector2,
            bytes memory storedReceiver2,
            bytes memory storedData2
        ) = router.storedMessages(messageHash);

        assertTrue(router.isDuplicateMessage(messageHash), "Message should not be marked as delivered after execution");
        assertTrue(storedBlockNumber2 == 0, "Message should be deleted after sending");
    }

    /// @dev Tests delivering and executing of messages to delivered for execution
    function testExecuteMessagesMessageNotDelivered() public {
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

        vm.expectRevert(abi.encodeWithSelector(Errors.MessageNotDeliveredForExecution.selector));
        router.executeMessages(messages);
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
