// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {IEquitoVerifier} from "./interfaces/IEquitoVerifier.sol";
import {IEquitoFees} from "./interfaces/IEquitoFees.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "./libraries/EquitoMessageLibrary.sol";
import {Errors} from "./libraries/Errors.sol";

/// @title Router
/// @notice The Router contract is used in the Equito Protocol to exchange messages with different blockchains.
///         Equito Validators will listen to the events emitted by this contract's `sendMessage` function,
///         to collect and relay messages to the appropriate destination chains.
///         Equito Validators will also deliver messages to this contract, to be routed to the appropriate receivers.
contract Router is IRouter, IEquitoReceiver {
    /// @notice The chain selector for the chain where the Router contract is deployed.
    uint256 public immutable chainSelector;

    /// @notice The Equito Protocol address.
    address public equitoAddress;

    /// @notice The list of verifiers used to verify the messages.
    IEquitoVerifier[] public verifiers;

    /// @notice Stores the messages that have already been processed to prevent replay attacks,
    ///         avoiding duplicate messages to be processed twice, hence the name.
    mapping(bytes32 => bool) public isDuplicateMessage;

    /// @notice Stores the message hashes that have been delivered and are awaiting execution.
    mapping(bytes32 => bool) public storedMessages;

    /// @notice The EquitoFees contract used to handle fee-related operations.
    /// @dev This contract reference is used to interact with the fee management system.
    IEquitoFees public equitoFees;

    /// @notice Initializes the Router contract with a chain selector, an initial verifier and the address of the EquitoFees contract..
    /// @param _chainSelector The chain selector of the chain where the Router contract is deployed.
    /// @notice Initializes the contract with the address of the EquitoFees contract.
    /// @param _initialVerifier The address of the initial verifier contract.
    constructor(uint256 _chainSelector, address _initialVerifier, address _equitoFees, address _equitoAddress) {
        if (_initialVerifier == address(0)) {
            revert Errors.InitialVerifierZeroAddress();
        }
        chainSelector = _chainSelector;
        verifiers.push(IEquitoVerifier(_initialVerifier));

        equitoFees = IEquitoFees(_equitoFees);

        equitoAddress = _equitoAddress;
    }

    modifier onlySovereign(EquitoMessage calldata message) {
        bytes64 memory _equitoAddress = EquitoMessageLibrary.addressToBytes64(equitoAddress);

        if (
            message.sourceChainSelector != 0 ||
            message.sender.lower != _equitoAddress.lower ||
            message.sender.upper != _equitoAddress.upper
        ) revert Errors.InvalidSovereign();
        _;
    }

    /// @notice Sends a cross-chain message using Equito.
    /// @param receiver The address of the receiver.
    /// @param destinationChainSelector The chain selector of the destination chain.
    /// @param data The message data.
    /// @return The hash of the message.
    function sendMessage(
        bytes64 calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external payable returns (bytes32) {
        equitoFees.payFee{value: msg.value}(msg.sender);

        EquitoMessage memory newMessage = EquitoMessage({
            blockNumber: block.number,
            sourceChainSelector: chainSelector,
            sender: EquitoMessageLibrary.addressToBytes64(msg.sender),
            destinationChainSelector: destinationChainSelector,
            receiver: receiver,
            hashedData: keccak256(data)
        });

        emit MessageSendRequested(newMessage, data);

        return keccak256(abi.encode(newMessage));
    }

    /// @notice Routes messages to the appropriate receiver contracts.
    /// @param messages The list of messages to be routed.
    /// @param messageData The data of the messages to be routed.
    /// @param verifierIndex The index of the verifier used to verify the messages.
    /// @param proof The proof provided by the verifier.
    function deliverAndExecuteMessages(
        EquitoMessage[] calldata messages,
        bytes[] calldata messageData,
        uint256 verifierIndex,
        bytes calldata proof
    ) external {
        if (verifierIndex >= verifiers.length) {
            revert Errors.InvalidVerifierIndex();
        }

        if (!verifiers[verifierIndex].verifyMessages(messages, proof)) {
            revert Errors.InvalidMessagesProof();
        }

        for (uint256 i = 0; i < messages.length; ) {
            bytes32 messageHash = keccak256(abi.encode(messages[i]));

            if (
                !isDuplicateMessage[messageHash] && 
                messages[i].hashedData == keccak256(messageData[i])
            ) {
                address receiver = 
                    EquitoMessageLibrary.bytes64ToAddress(messages[i].receiver);
                IEquitoReceiver(receiver)
                    .receiveMessage(messages[i], messageData[i]);
                isDuplicateMessage[messageHash] = true;
            }

            unchecked { ++i; }
        }

        emit MessageSendDelivered(messages);
    }

    /// @notice Delivers messages to be stored for later execution.
    /// @param messages The list of messages to be delivered.
    /// @param verifierIndex The index of the verifier used to verify the messages.
    /// @param proof The proof provided by the verifier.
    function deliverMessages(
        EquitoMessage[] calldata messages,
        uint256 verifierIndex,
        bytes calldata proof
    ) external {
        if (verifierIndex >= verifiers.length) {
            revert Errors.InvalidVerifierIndex();
        }

        if (!verifiers[verifierIndex].verifyMessages(messages, proof)) {
            revert Errors.InvalidMessagesProof();
        }

        for (uint256 i = 0; i < messages.length; ) {
            bytes32 messageHash = keccak256(abi.encode(messages[i]));

            if (!isDuplicateMessage[messageHash] && !storedMessages[messageHash]) {
                storedMessages[messageHash] = true;
            }

            unchecked { ++i; }
        }

        emit MessagesDelivered(messages);
    }

    /// @notice Executes the stored messages.
    /// @param messages The list of messages to be executed.
    /// @param messageData The data of the messages to be executed.
    function executeMessages(
        EquitoMessage[] calldata messages,
        bytes[] calldata messageData
    ) external {
        for (uint256 i = 0; i < messages.length; ) {
            bytes32 messageHash = keccak256(abi.encode(messages[i]));

            if (
                storedMessages[messageHash] &&
                !isDuplicateMessage[messageHash] &&
                messages[i].hashedData == keccak256(messageData[i])
            ) {
                address receiver = 
                    EquitoMessageLibrary.bytes64ToAddress(messages[i].receiver);
                IEquitoReceiver(receiver)
                    .receiveMessage(messages[i], messageData[i]);
                isDuplicateMessage[messageHash] = true;
                delete storedMessages[messageHash];
            } else {
                revert Errors.MessageNotDeliveredForExecution();
            }

            unchecked { ++i; }
        }

        emit MessagesExecuted(messages);
    }

    /// @notice Receives a cross-chain message from the Router contract.
    /// @param message The Equito message received.
    /// @param messageData The data of the message received.
    function receiveMessage(
        EquitoMessage calldata message,
        bytes calldata messageData
    ) external override onlySovereign(message) {
        bytes1 operation = messageData[0];

        if (operation == 0x01) {
            // Add verifier
            address newVerifier;
            uint256 verifierIndex;
            bytes memory proof;
            (, newVerifier, verifierIndex, proof) = abi.decode(
                messageData,
                (bytes32, address, uint256, bytes)
            );

            _addVerifier(
                newVerifier,
                verifierIndex,
                proof
            );
        } else if (operation == 0x02) {
            // Update the equito fees
            address newEquitoFees;
            (, newEquitoFees) = abi.decode(messageData, (bytes32, address));

            _setEquitoFees(newEquitoFees);
        } else if (operation == 0x03) {
            // Update the equito address
            address newEquitoAddress;
            (, newEquitoAddress) = abi.decode(messageData, (bytes32, address));

            _setEquitoAddress(newEquitoAddress);
        } else {
            revert Errors.InvalidOperation();
        }
    }

    /// @notice Adds a new verifier to the Router contract.
    ///         It requires a proof to be provided, to ensure that the Verifier is authorized to be added,
    ///         verified by one of the existing Verifiers, determined by `verifierIndex`.
    /// @param _newVerifier The address of the new verifier.
    /// @param verifierIndex The index of the verifier used to verify the new verifier.
    /// @param proof The proof provided by the verifier.
    function _addVerifier(
        address _newVerifier,
        uint256 verifierIndex,
        bytes memory proof
    ) internal {
        if (verifierIndex >= verifiers.length) {
            revert Errors.InvalidVerifierIndex();
        }

        if (verifiers[verifierIndex].verifySignatures(keccak256(abi.encodePacked(_newVerifier)), proof)) {
            verifiers.push(IEquitoVerifier(_newVerifier));
            emit VerifierAdded(_newVerifier);
        } else {
            revert Errors.InvalidNewVerifierProof(_newVerifier);
        }
    }

    /// @notice Sets the equitoFees.
    /// @param _equitoFees The new equito fees address to set.
    function _setEquitoFees(
        address _equitoFees
    ) internal {
        equitoFees = IEquitoFees(_equitoFees);
        emit EquitoFeesSet();
    }

    /// @notice Sets the equitoAddress.
    /// @param _equitoAddress The new equito address to set.
    function _setEquitoAddress(address _equitoAddress) internal {
        equitoAddress = _equitoAddress;
        emit EquitoAddressSet();
    }
}
