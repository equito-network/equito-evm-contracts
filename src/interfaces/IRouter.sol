// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessageLibrary} from "../libraries/EquitoMessageLibrary.sol";

interface IRouter {
    error InvalidAddress(bytes encodedAddress);
    error MessageSentAlready(bytes32 messageHash);
    error InvalidVerifierIndex(uint256 verifierIndex);

    event MessageSendRequested(
        address indexed sender,
        EquitoMessageLibrary.EquitoMessage data
    );
    event MessageSendDelivered(EquitoMessageLibrary.EquitoMessage[] messages);

    function sendMessage(
        bytes calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external returns (bytes32);

    function routeMessages(
        EquitoMessageLibrary.EquitoMessage[] calldata messages,
        uint256 verifierIndex
    ) external;
}
