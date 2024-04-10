// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {Client} from "./libraries/Client.sol";

contract Router is IRouter {
    IEquitoReceiver public equitoReceiver;
    uint256 public chainSelector;
    mapping(address => uint256) private _nonce;

    constructor(uint256 _chainSelector) {
        chainSelector = _chainSelector;
    }

    function sendMessage(
        address receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external returns (bytes32) {
        Client.EquitoMessage memory newMessage = Client.EquitoMessage({
            sourceChainSelector: chainSelector,
            sender: abi.encode(msg.sender),
            receiver: receiver,
            destinationChainSelector: destinationChainSelector,
            nonce: _nonce[msg.sender],
            data: data
        });

        _nonce[msg.sender] += 1;

        emit MessageSendRequested(msg.sender, newMessage);
        return Client._hash(newMessage);
    }

    function routeMessages(Client.EquitoMessage[] calldata messages) external {
        for (uint256 i = 0; i < messages.length; i++) {
            IEquitoReceiver(messages[i].receiver).receiveMessages(messages);
        }

        emit MessageSendDelivered(messages);
    }
}
