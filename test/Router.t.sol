// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Router, IRouter} from "../src/Router.sol";
import {EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockEquitoFees} from "./mock/MockEquitoFees.sol";
import {IEquitoVerifier} from "../src/interfaces/IEquitoVerifier.sol";
import {Errors} from "../src/libraries/Errors.sol";

/// @title RouterTest
/// @dev Test suite for the Router contract
contract RouterTest is Test {
    MockVerifier verifier;
    MockEquitoFees equitoFees;
    Router router;
    MockReceiver receiver;

    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);

    uint256 constant INITIAL_FEE = 0.1 ether;

    event MessageSendRequested(EquitoMessage message, bytes data);
    event VerifierAdded(address indexed verifier);
    event MessagesDelivered(EquitoMessage[] messages);
    event MessagesExecuted(EquitoMessage[] messages);
    event FeePaid(address indexed payer, uint256 amount);

    function setUp() public {
        verifier = new MockVerifier();
        equitoFees = new MockEquitoFees();
        router = new Router(1, address(verifier), address(equitoFees));
        receiver = new MockReceiver();
    }

    /// @dev Tests the constructor of the Router contract
    function testConstructor() public {
        assertEq(
            router.chainSelector(),
            1,
            "Chain selector not initialized correctly"
        );
    }

    // Test sending a message with no Ether
    function testSendMessageWithNoEther() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientFee.selector)
        );
        bytes32 messageHash = router.sendMessage(
            EquitoMessageLibrary.addressToBytes64(address(receiver)),
            1,
            "Test message"
        );
    }

    /// @dev Tests the sendMessage function of the Router contract
    function testSendMessage() public payable {
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        vm.expectEmit(true, true, true, true);
        emit FeePaid(ALICE, INITIAL_FEE);

        vm.expectEmit(true, true, true, true);
        emit MessageSendRequested(message, data);
        bytes32 messageHash = router.sendMessage{value: INITIAL_FEE}(
            EquitoMessageLibrary.addressToBytes64(address(receiver)),
            2,
            data
        );
        assertEq(keccak256(abi.encode(message)), messageHash);
    }

    /// @dev Tests delivering and executing of messages with a single message successfully
    function testDeliverAndExecuteMessagesSuccess() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = data;

        router.deliverAndExecuteMessages(messages, messageData, 0, abi.encode(1));
        assertTrue(
            router.isDuplicateMessage(keccak256(abi.encode(messages[0]))),
            "Message not delivered"
        );
    }

    /// @dev Tests delivering and executing of messages with an invalid verifier index
    function testDeliverAndExecuteMessagesInvalidVerifierIndex() public {
        bytes memory proof = abi.encode("proof");
        uint256 invalidVerifierIndex = 1;
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = data;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidVerifierIndex.selector)
        );
        router.deliverAndExecuteMessages(messages, messageData, invalidVerifierIndex, proof);
    }

    /// @dev Tests delivering and executing of messages with an invalid proof
    function testDeliverAndExecuteMessagesInvalidProof() public {
        bytes memory invalidProof = "";
        uint256 verifierIndex = 0;

        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = data;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidMessagesProof.selector)
        );
        router.deliverAndExecuteMessages(messages, messageData, verifierIndex, invalidProof);
    }

    /// @dev Tests delivering and executing of messages with duplicate messages
    function testDeliverAndExecuteMessagesWithDuplicateMessage() public {
        vm.prank(ALICE);
        bytes memory data1 = abi.encode("Hello, World!");

        EquitoMessage memory message1 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data1)
        });

        bytes memory data2 = abi.encode("This is a test!");

        EquitoMessage memory message2 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data2)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](3);
        messages[0] = message1;
        messages[1] = message2;
        messages[2] = message1;

        bytes[] memory messageData = new bytes[](3);
        messageData[0] = data1;
        messageData[1] = data2;
        messageData[2] = data1;

        bytes32 message1Hash = keccak256(abi.encode(message1));
        bytes32 message2Hash = keccak256(abi.encode(message2));

        router.deliverAndExecuteMessages(messages, messageData, 0, abi.encode(1));

        assertTrue(
            router.isDuplicateMessage(message1Hash),
            "Message not delivered"
        );
        assertTrue(
            router.isDuplicateMessage(message2Hash),
            "Message not delivered"
        );

        assertEq(receiver.getMessage().hashedData, message2.hashedData);
    }

    /// @dev Tests delivering of messages with a single message successfully
    function testDeliverMessagesSuccess() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;

        vm.expectEmit(true, true, false, true);
        emit MessagesDelivered(messages);

        router.deliverMessages(messages, 0, abi.encode(1));

        assertEq(
            router.storedMessages(keccak256(abi.encode(messages[0]))),
            true
        );
    }

    /// @dev Tests delivering and executing of messages with an invalid verifier index
    function testDeliverMessagesInvalidVerifierIndex() public {
        bytes memory proof = abi.encode("proof");
        uint256 invalidVerifierIndex = 1;
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidVerifierIndex.selector)
        );
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
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidMessagesProof.selector)
        );
        router.deliverMessages(messages, verifierIndex, invalidProof);
    }

    /// @dev Tests executing of messages with a single message successfully
    function testExecuteMessagesSuccess() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = data;

        bytes32 messageHash = keccak256(abi.encode(messages[0]));

        router.deliverMessages(messages, 0, abi.encode(1));
        assertTrue(router.storedMessages(messageHash), "Message not delivered");

        vm.expectEmit(true, true, false, true);
        emit MessagesExecuted(messages);

        router.executeMessages(messages, messageData);

        assertTrue(
            router.isDuplicateMessage(messageHash),
            "Message should not be marked as delivered after execution"
        );
        assertTrue(
            !router.storedMessages(messageHash),
            "Message should be deleted after sending"
        );
    }

    /// @dev Tests delivering and executing of messages to delivered for execution
    function testExecuteMessagesMessageNotDelivered() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = data;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.MessageNotDeliveredForExecution.selector
            )
        );
        router.executeMessages(messages, messageData);
    }

    /// @dev Tests adding a verifier to the Router contract successfully
    function testAddVerifierSuccess() public {
        vm.prank(BOB);
        bytes memory proof = abi.encode("proof");

        vm.expectEmit(true, true, true, true);
        emit VerifierAdded(BOB);

        router.addVerifier(BOB, 0, proof);

        assertEq(
            address(router.verifiers(1)),
            BOB,
            "The new verifier should be BOB"
        );
    }

    /// @dev Tests adding a verifier with an invalid verifier index
    function testAddVerifierInvalidVerifierIndex() public {
        bytes memory proof = abi.encode("proof");
        uint256 invalidVerifierIndex = 1;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidVerifierIndex.selector)
        );
        router.addVerifier(address(verifier), invalidVerifierIndex, proof);
    }

    /// @dev Tests adding a verifier with an invalid proof
    function testAddVerifierInvalidProof() public {
        uint256 verifierIndex = 0;
        bytes memory invalidProof = "";

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InvalidNewVerifierProof.selector,
                address(verifier)
            )
        );
        router.addVerifier(address(verifier), verifierIndex, invalidProof);
    }
}
