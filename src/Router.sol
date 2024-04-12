// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {EquitoMessage} from "./libraries/EquitoMessage.sol";

/// The Router contract is used in the Equito Protocol to exchange messages with different blockchains.
/// Equito Validators will listen to the events emitted by this contract's `sendMessage` function,
/// to collect and relay messages to the appropriate destination chains.
/// Equito Validators will also deliver messages to this contract, to be routed to the appropriate receivers.
contract Router is IRouter {
    /// The chain selector for the chain where the Router contract is deployed.
    uint256 public chainSelector;

    mapping(bytes32 => bool) public isMessageSent;

    constructor(uint256 _chainSelector) {
        chainSelector = _chainSelector;
    }

    /// Send a cross-chain message using Equito.
    function sendMessage(
        bytes calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external returns (bytes32) {
        EquitoMessage.EquitoMessage memory newMessage = EquitoMessage.EquitoMessage({
            blockNumber: block.number,
            sourceChainSelector: chainSelector,
            sender: abi.encode(msg.sender),
            destinationChainSelector: destinationChainSelector,
            receiver: receiver,
            data: data
        });

        emit MessageSendRequested(msg.sender, newMessage);

        return EquitoMessage._hash(newMessage);
    }

    /// Route messages to the appropriate receiver contracts.
    function routeMessages(EquitoMessage.EquitoMessage[] calldata messages) external {
        for (uint256 i = 0; i < messages.length; i++) {
            bytes32 messageHash = EquitoMessage._hash(messages[i]);

            if (isMessageSent[messageHash]) continue;

            address receiver = abi.decode(messages[i].receiver, (address));
            IEquitoReceiver(receiver).receiveMessage(messages[i]);
            isMessageSent[messageHash] = true;
        }

        emit MessageSendDelivered(messages);
    }
}
