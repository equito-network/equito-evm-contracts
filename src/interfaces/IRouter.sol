// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../libraries/EquitoMessageLibrary.sol";

interface IRouter {
    error InvalidAddress(bytes encodedAddress);
    error MessageSentAlready(bytes32 messageHash);

    event MessageSendRequested(
        address indexed sender,
        EquitoMessage data
    );
    event MessageSendDelivered(EquitoMessage[] messages);

    function sendMessage(
        bytes calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external returns (bytes32);

    function routeMessages(
        EquitoMessage[] calldata messages
    ) external;
}
