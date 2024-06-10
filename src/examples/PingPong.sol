// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "../EquitoApp.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../libraries/EquitoMessageLibrary.sol";

/// @title PingPong
/// @notice This contract implements a simple ping-pong message exchange using the Equito cross-chain messaging protocol.
contract PingPong is EquitoApp {

    /// @notice Event emitted when a ping message is sent.
    /// @param sender The address of the sender.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param message The ping message.
    event PingSent(address indexed sender, uint256 indexed destinationChainSelector, string message);

    /// @notice Event emitted when a pong message is received.
    /// @param sender The address of the sender.
    /// @param sourceChainSelector The identifier of the source chain.
    /// @param message The pong message.
    event PongReceived(address indexed sender, uint256 indexed sourceChainSelector, string message);

    /// @notice Thrown when attempting to set the router, but the router is already set.
    error RouterAlreadySet();

    /// @notice Thrown when an invalid message type is encountered.
    error InvalidMessageType();

    /// @notice Initializes the PingPong contract and sets the router address.
    /// @param _router The address of the router contract.
    constructor(address _router) EquitoApp(_router) {}

    /// @notice Sends a ping message to the specified address on another chain.
    /// @param receiver The address of the receiver.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param message The ping message.
    function sendPing(bytes64 calldata receiver, uint256 destinationChainSelector, string calldata message) external payable {
        bytes memory data = abi.encode("ping", message);
        this.sendMessage(receiver, destinationChainSelector, data);
        emit PingSent(msg.sender, destinationChainSelector, message);
    }

    /// @notice Receives a message from the router and handles it.
    /// @param message The Equito message received.
    /// @param messageData The data of the message received.
    function _receiveMessageFromPeer(EquitoMessage calldata message, bytes calldata messageData) internal override {
        (string memory messageType, string memory payload) = abi.decode(messageData, (string, string));

        if (keccak256(bytes(messageType)) == keccak256(bytes("ping"))) {
            sendPong(message.sender, message.sourceChainSelector, payload);
        } else if (keccak256(bytes(messageType)) == keccak256(bytes("pong"))) {
            emit PongReceived(EquitoMessageLibrary.bytes64ToAddress(message.sender), message.sourceChainSelector, payload);
        } else {
            revert InvalidMessageType();
        }
    }

    /// @notice Sends a pong message in response to a received ping.
    /// @param receiver The address of the receiver.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param message The pong message.
    function sendPong(bytes64 memory receiver, uint256 destinationChainSelector, string memory message) internal {
        bytes memory data = abi.encode("pong", message);
        this.sendMessage(receiver, destinationChainSelector, data);
    }
}
