// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Router, IRouter} from "../src/Router.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
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
    address equitoAddress = address(0x45717569746f);

    uint256 constant INITIAL_FEE = 0.1 ether;

    event MessageSendRequested(EquitoMessage message, bytes data);
    event VerifierAdded(address indexed verifier);
    event MessageDelivered(bytes32 messageHash);
    event MessageExecuted(bytes32 messageHash);
    event FeePaid(address indexed payer, uint256 amount);
    event EquitoAddressSet();
    event EquitoFeesSet();

    function setUp() public {
        verifier = new MockVerifier();
        equitoFees = new MockEquitoFees();
        router = new Router(
            1,
            address(verifier),
            address(equitoFees),
            EquitoMessageLibrary.addressToBytes64(equitoAddress)
        );
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

    /// @dev Tests delivering and executing of a message
    function testDeliverAndExecuteMessageSuccess() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        router.deliverAndExecuteMessage(message, data, 0, abi.encode(1));
        assertTrue(
            router.isDuplicateMessage(keccak256(abi.encode(message))),
            "Message not delivered"
        );
    }

    /// @dev Tests delivering and executing of messages with an invalid verifier index
    function testDeliverAndExecuteMessageInvalidVerifierIndex() public {
        bytes memory proof = abi.encode("proof");
        uint256 invalidVerifierIndex = 1;
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidVerifierIndex.selector)
        );
        router.deliverAndExecuteMessage(
            message,
            data,
            invalidVerifierIndex,
            proof
        );
    }

    /// @dev Tests delivering and executing of messages with an invalid proof
    function testDeliverAndExecuteMessageInvalidProof() public {
        bytes memory invalidProof = "";

        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidMessagesProof.selector)
        );
        router.deliverAndExecuteMessage(message, data, 0, invalidProof);
    }

    /// @dev Tests delivering and executing of messages with duplicate messages
    function testDeliverAndExecuteMessageWithDuplicateMessage() public {
        vm.prank(ALICE);
        bytes memory data1 = abi.encode("Hello, World!");

        EquitoMessage memory message1 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data1)
        });

        bytes memory data2 = abi.encode("This is a test!");

        EquitoMessage memory message2 = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data2)
        });

        bytes32 message1Hash = keccak256(abi.encode(message1));
        bytes32 message2Hash = keccak256(abi.encode(message2));

        router.deliverAndExecuteMessage(message1, data1, 0, abi.encode(1));
        router.deliverAndExecuteMessage(message2, data2, 0, abi.encode(1));

        assertTrue(
            router.isDuplicateMessage(message1Hash),
            "Message not delivered"
        );
        assertTrue(
            router.isDuplicateMessage(message2Hash),
            "Message not delivered"
        );

        assertEq(receiver.getMessage().hashedData, message2.hashedData);

        router.deliverAndExecuteMessage(message1, data1, 0, abi.encode(1));
        assertEq(receiver.getMessage().hashedData, message2.hashedData);
    }

    /// @dev Tests delivering of messages with a single message successfully
    function testDeliverMessagesSuccess() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;

        vm.expectEmit(true, true, false, true);
        emit MessageDelivered(keccak256(abi.encode(message)));

        router.deliverMessages(messages, 0, abi.encode(1));

        assertTrue(router.storedMessages(keccak256(abi.encode(messages[0]))));
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
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 1,
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
    function testExecuteMessageSuccess() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 1,
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
        emit MessageExecuted(keccak256(abi.encode(message)));

        router.executeMessage(message, data);

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
    function testExecuteMessageMessageNotDelivered() public {
        vm.prank(ALICE);
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        router.executeMessage(message, data);

        assertFalse(
            keccak256(abi.encode(receiver.getMessage())) ==
                keccak256(abi.encode(message)),
            "Undelivered message should not be executed"
        );
    }

    /// @notice Tests the receive message with add verifier command.
    function testReceiveMessageAddVerifier() external {
        MockVerifier newVerifier = new MockVerifier();

        bytes memory data = abi.encode(bytes1(0x01), address(newVerifier));

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(router)),
            hashedData: keccak256(data)
        });

        vm.prank(address(router));
        vm.expectEmit(true, true, true, true);
        emit VerifierAdded(address(newVerifier));
        router.receiveMessage(message, data);

        assertEq(
            address(router.verifiers(1)),
            address(newVerifier),
            "The new verifier should be set"
        );

        assertEq(
            newVerifier.router(),
            address(router),
            "The router address should be set"
        );
    }

    /// @notice Tests the receive message with set equito fees command.
    function testReceiveMessageSetEquitoFees() external {
        bytes64 memory newEquitoFees = EquitoMessageLibrary.addressToBytes64(
            address(0xbeef)
        );

        bytes memory data = abi.encode(bytes1(0x02), newEquitoFees);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: keccak256(data)
        });

        vm.prank(address(router));
        vm.expectEmit(true, true, true, true);
        emit EquitoFeesSet();
        router.receiveMessage(message, data);

        bytes64 memory _equitoFees = EquitoMessageLibrary.addressToBytes64(
            address(router.equitoFees())
        );

        assert(
            _equitoFees.lower == newEquitoFees.lower &&
                _equitoFees.upper == newEquitoFees.upper
        );
    }

    /// @notice Tests the receive message with set equito address command.
    function testReceiveMessageSetEquitoAddress() external {
        bytes64 memory newEquitoAddress = EquitoMessageLibrary.addressToBytes64(
            address(0xbeef)
        );

        bytes memory data = abi.encode(bytes1(0x03), newEquitoAddress);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: keccak256(data)
        });

        vm.prank(address(router));
        vm.expectEmit(true, true, true, true);
        emit EquitoAddressSet();
        router.receiveMessage(message, data);

        (bytes32 lower, bytes32 upper) = router.equitoAddress();

        assert(
            lower == newEquitoAddress.lower && upper == newEquitoAddress.upper
        );
    }

    /// @notice Tests the receive message with invalid command.
    function testReceiveMessageInvalidOperation() external {
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: keccak256(abi.encode(bytes1(0x07)))
        });

        vm.prank(address(router));
        vm.expectRevert(Errors.InvalidOperation.selector);
        router.receiveMessage(message, abi.encode(bytes1(0x07)));
    }

    /// @notice Tests the message with invalid destination chain selector.
    function testMessageInvalidDestinationChainSelector() external {
        bytes memory data = abi.encode("Hello, World!");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(address(receiver)),
            hashedData: keccak256(data)
        });

        bytes32 messageHash = keccak256(abi.encode(message));

        router.deliverAndExecuteMessage(message, data, 0, abi.encode(1));

        Vm.Log[] memory entriesDeliverExecute = vm.getRecordedLogs();
        assertEq(entriesDeliverExecute.length, 0, "No logs should be emitted");
        assertFalse(
            router.storedMessages(messageHash),
            "Message should not be delivered"
        );
        assertFalse(
            router.isDuplicateMessage(messageHash),
            "Message should not be marked as duplicate"
        );
        assertNotEq(
            receiver.getMessage().hashedData,
            message.hashedData,
            "Message should not be received"
        );

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;
        router.deliverMessages(messages, 0, abi.encode(1));

        Vm.Log[] memory entriesDeliver = vm.getRecordedLogs();
        assertEq(entriesDeliver.length, 0, "No logs should be emitted");
        assertFalse(
            router.storedMessages(messageHash),
            "Message should not be delivered"
        );

        router.executeMessage(message, data);
        Vm.Log[] memory entriesExecute = vm.getRecordedLogs();
        assertEq(entriesExecute.length, 0, "No logs should be emitted");
        assertFalse(
            router.isDuplicateMessage(messageHash),
            "Message should not be marked as duplicate"
        );
        assertNotEq(
            receiver.getMessage().hashedData,
            message.hashedData,
            "Message should not be received"
        );
    }
}
