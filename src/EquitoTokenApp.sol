// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import {EquitoApp} from "./EquitoApp.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {bytes64, EquitoMessage} from "./libraries/EquitoMessageLibrary.sol";
import {Errors} from "./libraries/Errors.sol";

/// @title EquitoTokenApp
/// @notice Improved version of EquitoApp for token transfers and swaps.
///         EquitoTokenApp extends EquitoApp to handle cross-chain messages
///         with `uint256 amount` and `bytes64 tokenAddress` instead of arbitrary data.
abstract contract EquitoTokenApp is EquitoApp {
    /// @notice Initializes the EquitoTokenApp contract and sets the router address.
    /// @param _router The address of the router contract.
    constructor(address _router) EquitoApp(_router) {}

    /// @notice Sends a cross-chain token transfer message using Equito.
    /// @param receiver The address of the receiver.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param amount The amount of tokens to transfer.
    /// @param tokenAddress The address of the token contract.
    /// @return The message ID.
    function sendToken(
        bytes64 calldata receiver,
        uint256 destinationChainSelector,
        uint256 amount,
        bytes64 memory tokenAddress
    ) external payable returns (bytes32) {
        bytes memory data = abi.encode(amount, tokenAddress);
        return router.sendMessage{value: msg.value}(receiver, destinationChainSelector, data);
    }

    /// @notice Sends a cross-chain token transfer message to a known peer using Equito.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param amount The amount of tokens to transfer.
    /// @param tokenAddress The address of the token contract.
    /// @return The message ID.
    function sendTokenToPeer(
        uint256 destinationChainSelector,
        uint256 amount,
        bytes64 calldata tokenAddress
    ) external payable returns (bytes32) {
        bytes64 memory peerAddress = peers[destinationChainSelector];
        if (peerAddress.lower == 0 && peerAddress.upper == 0) {
            revert Errors.InvalidPeerAddress();
        }
        bytes memory data = abi.encode(amount, tokenAddress);
        return router.sendMessage{value: msg.value}(peerAddress, destinationChainSelector, data);
    }

    /// @notice Handles the reception of a cross-chain message from a peer.
    ///         Decodes the `amount` and `tokenAddress` from the message data.
    /// @param message The Equito message received.
    /// @param messageData The data of the message received.
    function _receiveMessageFromPeer(
        EquitoMessage calldata message,
        bytes calldata messageData
    ) internal override {
        (uint256 amount, bytes64 memory tokenAddress) = abi.decode(messageData, (uint256, bytes64));
        _receiveTokenFromPeer(message, amount, tokenAddress);
    }

    /// @notice Handles the reception of a cross-chain message from a non-peer.
    ///         Decodes the `amount` and `tokenAddress` from the message data.
    /// @param message The Equito message received.
    /// @param messageData The data of the message received.
    function _receiveMessageFromNonPeer(
        EquitoMessage calldata message,
        bytes calldata messageData
    ) internal override {
        (uint256 amount, bytes64 memory tokenAddress) = abi.decode(messageData, (uint256, bytes64));
        _receiveTokenFromNonPeer(message, amount, tokenAddress);
    }

    /// @notice Handle the logic for token transfer from a peer.
    /// @param message The Equito message received.
    /// @param amount The amount of tokens transferred.
    /// @param tokenAddress The address of the token contract.
    function _receiveTokenFromPeer(
        EquitoMessage calldata message,
        uint256 amount,
        bytes64 memory tokenAddress
    ) internal virtual {}

    /// @notice Handle the logic for token transfer from a non-peer.
    ///         The default implementation reverts the transaction.
    /// @param message The Equito message received.
    /// @param amount The amount of tokens transferred.
    /// @param tokenAddress The address of the token contract.
    function _receiveTokenFromNonPeer(
        EquitoMessage calldata message,
        uint256 amount,
        bytes64 memory tokenAddress
    ) internal virtual {
        revert Errors.InvalidMessageSender();
    }
}