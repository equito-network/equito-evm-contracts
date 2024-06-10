// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "../EquitoApp.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../libraries/EquitoMessageLibrary.sol";

/// @title PingPong
/// @notice This contract implements a simple ping-pong message exchange using the Equito cross-chain messaging protocol.
contract PingPong is EquitoApp {

    /// @notice Event emitted when a ping message is sent.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param message The ping message.
    event PingSent(uint256 indexed destinationChainSelector, string message);

    /// @notice Event emitted when a ping message is received.
    /// @param sourceChainSelector The identifier of the source chain.
    /// @param message The ping message.
    event PingReceived(uint256 indexed sourceChainSelector, string message);

    /// @notice Event emitted when a pong message is received.
    /// @param sourceChainSelector The identifier of the source chain.
    /// @param message The pong message.
    event PongReceived(uint256 indexed sourceChainSelector, string message);

    /// @notice Thrown when attempting to set the router, but the router is already set.
    error RouterAlreadySet();

    /// @notice Thrown when an invalid message type is encountered.
    error InvalidMessageType();

    /// @notice Initializes the PingPong contract and sets the router address.
    /// @param _router The address of the router contract.
    constructor(address _router) EquitoApp(_router) {}

    /// @notice Sends a ping message to the specified address on another chain.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param message The ping message.
    function sendPing(uint256 destinationChainSelector, string calldata message) external payable {
        bytes memory data = abi.encode("ping", message);
        bytes64 memory receiver = peers[destinationChainSelector];

        this.sendMessage(receiver, destinationChainSelector, data);
        emit PingSent(destinationChainSelector, message);
    }

    /// @notice Receives a message from the router and handles it.
    /// @param message The Equito message received.
    /// @param messageData The data of the message received.
    function _receiveMessageFromPeer(EquitoMessage calldata message, bytes calldata messageData) internal override {
        (string memory messageType, string memory payload) = abi.decode(messageData, (string, string));

        if (keccak256(bytes(messageType)) == keccak256(bytes("ping"))) {
            emit PingReceived(message.sourceChainSelector, payload);
            sendPong(message.sourceChainSelector, payload);
        } else if (keccak256(bytes(messageType)) == keccak256(bytes("pong"))) {
            emit PongReceived(message.sourceChainSelector, payload);
        } else {
            revert InvalidMessageType();
        }
    }

    /// @notice Sends a pong message in response to a received ping.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param message The pong message.
    function sendPong(uint256 destinationChainSelector, string memory message) internal {
        bytes memory data = abi.encode("pong", message);
        bytes64 memory receiver = peers[destinationChainSelector];

        this.sendMessage(receiver, destinationChainSelector, data);
    }
}
