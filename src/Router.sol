// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {Client} from "./libraries/Client.sol";

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
        Client.EquitoMessage memory newMessage = Client.EquitoMessage({
            blockNumber: block.number,
            sourceChainSelector: chainSelector,
            sender: abi.encode(msg.sender),
            destinationChainSelector: destinationChainSelector,
            receiver: receiver,
            data: data
        });

        bytes32 messageHash = Client._hash(newMessage);

        if (isMessageSent[messageHash]) revert MessageSentAlready(messageHash);

        emit MessageSendRequested(msg.sender, newMessage);
        isMessageSent[messageHash] = true;
        return Client._hash(newMessage);
    }

    /// Route messages to the appropriate receiver contracts.
    function routeMessages(Client.EquitoMessage[] calldata messages) external {
        for (uint256 i = 0; i < messages.length; i++) {
            address receiver = abi.decode(messages[i].receiver, (address));
            IEquitoReceiver(receiver).receiveMessages(messages);
        }

        emit MessageSendDelivered(messages);
    }
}
