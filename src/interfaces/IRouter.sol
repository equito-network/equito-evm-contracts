// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../libraries/EquitoMessage.sol";

interface IRouter {
    error InvalidAddress(bytes encodedAddress);
    error MessageSentAlready(bytes32 messageHash);

    event MessageSendRequested(
        address indexed sender,
        EquitoMessage.EquitoMessage data
    );
    event MessageSendDelivered(EquitoMessage.EquitoMessage[] messages);

    function sendMessage(
        bytes calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external returns (bytes32);

    function routeMessages(
        EquitoMessage.EquitoMessage[] calldata messages
    ) external;
}
