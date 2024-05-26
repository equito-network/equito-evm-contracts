// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {EquitoMessage} from "./libraries/EquitoMessageLibrary.sol";
import {Errors} from "./libraries/Errors.sol";
import {console} from "forge-std/console.sol";

/// @title EquitoApp
/// @notice This abstract contract is the base for all applications that want to leverage 
///         the Equito cross-chain messaging protocol to communicate with other blockchains.
abstract contract EquitoApp is IEquitoReceiver, Ownable {
    /// @dev The Router Contract that is used to send and receive messages.
    IRouter internal immutable router;

    /// @dev Mapping to store peer addresses for different chain IDs.
    mapping(uint256 => bytes) public peers;

    /// @notice Initializes the EquitoApp contract and set the router address.
    /// @param _router The address of the router contract.
    constructor(address _router) Ownable(msg.sender) {
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

    /// @notice Allows the owner to set the peer addresses for different chain IDs.
    /// @param chainIds The list of chain IDs.
    /// @param addresses The list of addresses corresponding to the chain IDs.
    function setPeers(uint256[] calldata chainIds, bytes[] calldata addresses) external onlyOwner {
        _setPeers(chainIds, addresses);
    }

    /// @notice Internal function to set the peer addresses for different chain IDs.
    /// @param chainIds The list of chain IDs.
    /// @param addresses The list of addresses corresponding to the chain IDs.
    /// @dev This function is internal to allow for easier overriding and extension by derived contracts,
    ///      facilitating the reuse of peer-setting logic in different contexts.
    function _setPeers(uint256[] calldata chainIds, bytes[] calldata addresses) internal virtual onlyOwner {
        if (chainIds.length != addresses.length)
            revert Errors.InvalidLength();

        for (uint256 i = 0; i < chainIds.length; ) {
            peers[chainIds[i]] = addresses[i];

            unchecked { ++i; }
        }
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
    ///         It is a wrapper function for the `_receiveMessage` function, that needs to be overridden.
    ///         Only the Router Contract is allowed to call this function.
    /// @param message The Equito message received.
    function receiveMessage(EquitoMessage calldata message) external override onlyRouter {
        bytes memory peerAddress = peers[message.sourceChainSelector];

        if (peerAddress.length != 0 && keccak256(peerAddress) == keccak256(message.sender)) {
            _receiveMessageFromPeer(message);
        } else {
            _receiveMessageFromNonPeer(message);
        }
    }

    /// @notice The logic for receiving a cross-chain message from a peer.
    /// @param message The Equito message received.
    function _receiveMessageFromPeer(EquitoMessage calldata message) internal virtual;

    /// @notice The logic for receiving a cross-chain message from a non-peer.
    ///         The default implementation reverts the transaction.
    /// @param message The Equito message received.
    function _receiveMessageFromNonPeer(EquitoMessage calldata message) internal virtual {
        revert Errors.InvalidMessageSender();
    }
}