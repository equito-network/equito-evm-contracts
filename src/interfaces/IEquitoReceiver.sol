// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../libraries/EquitoMessageLibrary.sol";

interface IEquitoReceiver {
    /// @notice Event emitted when a message is sent.
    /// @param receiver The address of the receiver.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param data The message data.
    event MessageSent(bytes indexed receiver, uint256 indexed destinationChainSelector, bytes data);

    /// @notice Event emitted when a message is received.
    /// @param sender The address of the sender.
    /// @param data The message data.
    event MessageReceived(address indexed sender, bytes data);

    /// @notice Receives a cross-chain message from the Router Contract.
    /// @param message The Equito message received.
    function receiveMessage(EquitoMessage calldata message) external;
}
