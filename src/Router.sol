// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {Client} from "./libraries/Client.sol";

contract Router is IRouter {
    /// The chain selector for the chain where the Router contract is deployed.
    uint256 public chainSelector;

    constructor(uint256 _chainSelector) {
        chainSelector = _chainSelector;
    }

    /// Send a cross-chain message using Equito.
    function sendMessage(
        bytes receiver,
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


        emit MessageSendRequested(newMessage);
        return Client._hash(newMessage);
    }

    /// Route messages to the appropriate receiver contracts.
    function routeMessages(Client.EquitoMessage[] calldata messages) external {
        for (uint256 i = 0; i < messages.length; i++) {
            IEquitoReceiver(abi.decode(messages[i].receiver)).receiveMessages(messages);
        }

        emit MessageSendDelivered(messages);
    }
}
