// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

interface IRouter {
    struct EquitoMessage {
        uint256 nonce; // Nonce of the message.
        uint256 sourceChainSelector; // Source chain selector.
        bytes sender; // abi.decode(sender) if coming from an EVM chain.
        uint256 destinationChainSelector; // Destination chain selector.
        address receiver; // Receiver address
        bytes data; // payload sent in original message.
    }

    event MessageSendRequested(address indexed sender, EquitoMessage data);

    function sendMessage(
        EquitoMessage calldata message
    ) external returns (bytes32);
}
