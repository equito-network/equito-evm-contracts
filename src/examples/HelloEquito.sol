// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoApp} from "../EquitoApp.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../libraries/EquitoMessageLibrary.sol";

/// @title HelloEquito
/// @notice This contract implements a simple hello message exchange using the Equito cross-chain messaging protocol.
contract HelloEquito is EquitoApp {

    /// @notice Event emitted when an hello message is sent.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param messageHash The hello message hash.
    event HelloMessageSent(
        uint256 indexed destinationChainSelector,
        bytes32 messageHash
    );

    /// @notice Event emitted when an hello message is received.
    /// @param sourceChainSelector The identifier of the source chain.
    /// @param messageHash The hello message hash.
    /// @param messageData The data of the hello message.
    event HelloMessageReceived(
        uint256 indexed sourceChainSelector,
        bytes32 messageHash,
        bytes messageData
    );

    /// @notice Initializes the HelloEquito contract and sets the router address.
    /// @param _router The address of the router contract.
    /// @dev The router address is set in the constructor of the EquitoApp contract.
    constructor(address _router) EquitoApp(_router) {}

    /// @notice Sends a hello message to the peer address on the specified chain.
    /// @param destinationChainSelector The identifier of the destination chain.
    function sendMessage(uint256 destinationChainSelector) external payable {
        bytes memory data = abi.encode("Hello, Equito!");

        bytes32 messageHash = router.sendMessage{value: msg.value}(
            getPeer(destinationChainSelector),
            destinationChainSelector,
            data
        );

        emit HelloMessageSent(destinationChainSelector, messageHash);
    }

    /// @notice Receives a cross-chain message created by a peer and validated by the Router Contract.
    /// @param message The Equito message received.
    /// @param messageData The data of the message received.
    function _receiveMessageFromPeer(
        EquitoMessage calldata message,
        bytes calldata messageData
    ) internal override {
        emit HelloMessageReceived(
            message.sourceChainSelector,
            keccak256(abi.encode(message)),
            messageData
        );
    }
}
