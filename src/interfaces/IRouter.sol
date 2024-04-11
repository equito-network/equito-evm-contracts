// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Client} from "../libraries/Client.sol";

interface IRouter {
    error InvalidAddress(bytes encodedAddress);
    error MessageSentAlready(bytes32 messageHash);

    event MessageSendRequested(
        address indexed sender,
        Client.EquitoMessage data
    );
    event MessageSendDelivered(Client.EquitoMessage[] messages);

    function sendMessage(
        bytes calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external returns (bytes32);

    function routeMessages(Client.EquitoMessage[] calldata messages) external;
}
