// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {IEquitoVerifier} from "./interfaces/IEquitoVerifier.sol";
import {EquitoMessage, EquitoMessageLibrary} from "./libraries/EquitoMessageLibrary.sol";
import {Errors} from "./libraries/Errors.sol";

/// @title Router
/// @notice The Router contract is used in the Equito Protocol to exchange messages with different blockchains.
///         Equito Validators will listen to the events emitted by this contract's `sendMessage` function,
///         to collect and relay messages to the appropriate destination chains.
///         Equito Validators will also deliver messages to this contract, to be routed to the appropriate receivers.
contract Router is IRouter {
    /// @notice The chain selector for the chain where the Router contract is deployed.
    uint256 public immutable chainSelector;

    /// @notice The list of verifiers used to verify the messages.
    IEquitoVerifier[] public verifiers;

    /// @notice Stores the messages that have already been processed to prevent replay attacks,
    ///         avoiding duplicate messages to be processed twice, hence the name.
    mapping(bytes32 => bool) public isDuplicateMessage;

    /// @notice Initializes the Router contract with a chain selector and an initial verifier.
    /// @param _chainSelector The chain selector of the chain where the Router contract is deployed.
    /// @param _initialVerifier The address of the initial verifier contract.
    constructor(uint256 _chainSelector, address _initialVerifier) {
        if (_initialVerifier == address(0)) {
            revert Errors.InitialVerifierZeroAddress();
        }
        chainSelector = _chainSelector;
        verifiers.push(IEquitoVerifier(_initialVerifier));
    }

    /// @notice Sends a cross-chain message using Equito.
    /// @param receiver The address of the receiver.
    /// @param destinationChainSelector The chain selector of the destination chain.
    /// @param data The message data.
    /// @return The hash of the message.
    function sendMessage(
        bytes calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external returns (bytes32) {
        EquitoMessage memory newMessage = EquitoMessage({
            blockNumber: block.number,
            sourceChainSelector: chainSelector,
            sender: abi.encode(msg.sender),
            destinationChainSelector: destinationChainSelector,
            receiver: receiver,
            data: data
        });

        emit MessageSendRequested(msg.sender, newMessage);

        return EquitoMessageLibrary._hash(newMessage);
    }

    /// @notice Routes messages to the appropriate receiver contracts.
    /// @param messages The list of messages to be routed.
    /// @param verifierIndex The index of the verifier used to verify the messages.
    /// @param proof The proof provided by the verifier.
    function routeMessages(
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
            bytes32 messageHash = EquitoMessageLibrary._hash(messages[i]);

            if (!isDuplicateMessage[messageHash]) {
                address receiver = abi.decode(messages[i].receiver, (address));
                IEquitoReceiver(receiver).receiveMessage(messages[i]);
                isDuplicateMessage[messageHash] = true;
            }

            unchecked { ++i; }
        }

        emit MessageSendDelivered(messages);
    }

    /// @notice Adds a new verifier to the Router contract.
    ///         It requires a proof to be provided, to ensure that the Verifier is authorized to be added,
    ///         verified by one of the existing Verifiers, determined by `verifierIndex`.
    /// @param _newVerifier The address of the new verifier.
    /// @param verifierIndex The index of the verifier used to verify the new verifier.
    /// @param proof The proof provided by the verifier.
    function addVerifier(
        address _newVerifier,
        uint256 verifierIndex,
        bytes calldata proof
    ) external {
        if (verifierIndex >= verifiers.length) {
            revert Errors.InvalidVerifierIndex();
        }

        if (verifiers[verifierIndex].verifySignatures(keccak256(abi.encode(_newVerifier)), proof)) {
            verifiers.push(IEquitoVerifier(_newVerifier));
            emit VerifierAdded(_newVerifier);
        } else {
            revert Errors.InvalidNewVerifierProof(_newVerifier);
        }
    }
}
