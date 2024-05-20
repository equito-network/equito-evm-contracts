// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {EquitoMessage} from "./libraries/EquitoMessageLibrary.sol";
import {Errors} from "./libraries/Errors.sol";

/// @title EquitoApp
/// @notice This abstract contract is the base for all applications that want to leverage 
/// the Equito cross-chain messaging protocol to communicate with other blockchains.
abstract contract EquitoApp is IEquitoReceiver {
    /// @dev The Router Contract that is used to send and receive messages.
    IRouter internal immutable router;

    /// @notice Initializes the EquitoApp contract and set the router address.
    /// @param _router The address of the router contract.
    constructor(address _router) {
        if (_router == address(0)) {
            revert Errors.RouterAddressCannotBeZero();
        }
        router = IRouter(_router);
    }

    /// @notice Modifier to restrict access to only the router contract.
    modifier onlyRouter() {
        if (msg.sender != address(router)) revert Errors.InvalidRouter(msg.sender);
        _;
    }

    /// @notice Sends a cross-chain message using Equito.
    /// @param receiver The address of the receiver.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param data The message data.
    /// @return The message ID.
    function sendMessage(
        bytes calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external returns (bytes32) {
        return router.sendMessage(receiver, destinationChainSelector, data);
    }

    /// @notice Receives a cross-chain message from the Router Contract.
    /// It is a wrapper function for the `_receiveMessage` function, that needs to be overridden.
    /// Only the Router Contract is allowed to call this function.
    /// @param message The Equito message received.
    function receiveMessage(EquitoMessage calldata message) external override onlyRouter {
        _receiveMessage(message);
    }

    /// @notice The actual logic for receiving a cross-chain message from the Router Contract
    /// needs to be implemented in this function.
    /// @param message The Equito message received.
    function _receiveMessage(EquitoMessage calldata message) internal virtual;
}