// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../libraries/EquitoMessageLibrary.sol";

// Interface for the Router contract, used to interact with cross-chain messaging protocol
interface IRouter {
    /// @notice Emitted when a message send request is created.
    /// @param sender The sender of the message.
    /// @param message The message being sent.
    event MessageSendRequested(address indexed sender, EquitoMessage message);

    /// @notice Emitted when messages are delivered to their destination.
    /// @param messages The list of messages that were delivered.
    event MessageSendDelivered(EquitoMessage[] messages);

    /// @notice Emitted when a new verifier is added.
    /// @param verifier The address of the new verifier.
    event VerifierAdded(address indexed verifier);

    /// @notice Emitted when messages are successfully delivered for execution.
    /// @param messages The list of messages that have been delivered for execution.
    event MessagesDelivered(EquitoMessage[] messages);

    /// @notice Emitted when messages are successfully executed.
    /// @param messages The list of messages that have been executed.
    event MessagesExecuted(EquitoMessage[] messages);

    /// @notice Sends a cross-chain message using Equito.
    /// @param receiver The address of the receiver.
    /// @param destinationChainSelector The chain selector of the destination chain.
    /// @param data The message data.
    /// @return The hash of the message.
    function sendMessage(
        bytes calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external returns (bytes32);

    /// @notice Routes messages to the appropriate receiver contracts.
    /// @param messages The list of messages to be routed.
    /// @param verifierIndex The index of the verifier used to verify the messages.
    /// @param proof The proof provided by the verifier.
    function deliverAndExecuteMessages(
        EquitoMessage[] calldata messages,
        uint256 verifierIndex,
        bytes calldata proof
    ) external;

    /// @notice Delivers messages to be stored for later execution.
    /// @param messages The list of messages to be delivered.
    /// @param verifierIndex The index of the verifier used to verify the messages.
    /// @param proof The proof provided by the verifier.
    function deliverMessages(
        EquitoMessage[] calldata messages,
        uint256 verifierIndex,
        bytes calldata proof
    ) external;

    /// @notice Executes the stored messages.
    /// @param messages The list of messages to be executed.
    function executeMessages(
        EquitoMessage[] calldata messages
    ) external;

    /// @notice Adds a new verifier to the Router contract.
    /// @param _newVerifier The address of the new verifier.
    /// @param verifierIndex The index of the verifier used to verify the new verifier.
    /// @param proof The proof provided by the verifier.
    function addVerifier(
        address _newVerifier,
        uint256 verifierIndex,
        bytes calldata proof
    ) external;

    /// @notice Returns the chain selector of the current chain.
    function chainSelector() external view returns (uint256);
}
