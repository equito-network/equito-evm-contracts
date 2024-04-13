// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {EquitoMessage} from "./libraries/EquitoMessage.sol";

/// This abstract contract is the base for all applications that want to leverage 
/// the Equito cross-chain messaging protocol to communicate with other blockchains.
abstract contract EquitoApp is IEquitoReceiver {
    error InvalidRouter(address router);
  
    /// The Router Contract that is used to send and receive messages.
    IRouter internal immutable router;

    constructor(address _router) {
        router = IRouter(_router);
    }

    /// Only the Router Contract is allowed to call the functions with this modifier.
    modifier onlyRouter() {
        if (msg.sender != address(router)) revert InvalidRouter(msg.sender);
        _;
    }

    /// Send a cross-chain message using Equito.
    function sendMessage(
        bytes calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external returns (bytes32) {
        return router.sendMessage(receiver, destinationChainSelector, data);
    }

    /// Receive a cross-chain message from the Router Contract.
    /// It is a wrapper function for the `_receiveMessage` function, that needs to be overridden.
    /// Only the Router Contract is allowed to call this function.
    function receiveMessage(EquitoMessage.EquitoMessage calldata message) external override onlyRouter {
        _receiveMessage(message);
    }

    /// The actual logic for receiving a cross-chain message from the Router Contract
    /// needs to be implemented in this function.
    function _receiveMessage(EquitoMessage.EquitoMessage calldata message) internal virtual;
}