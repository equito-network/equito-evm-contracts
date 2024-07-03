// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {bytes64, EquitoMessage} from "./libraries/EquitoMessageLibrary.sol";
import {Errors} from "./libraries/Errors.sol";

/// @title EquitoApp
/// @notice This abstract contract is the base for all applications that want to leverage
///         the Equito cross-chain messaging protocol to communicate with other blockchains.
abstract contract EquitoApp is IEquitoReceiver, Ownable {
    /// @dev The Router Contract that is used to send and receive messages.
    IRouter internal immutable router;

    /// @dev Mapping to store peer addresses for different chain IDs.
    mapping(uint256 => bytes64) public peers;

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
    function setPeers(uint256[] calldata chainIds, bytes64[] calldata addresses) external onlyOwner {
        _setPeers(chainIds, addresses);
    }

    /// @notice Internal function to set the peer addresses for different chain IDs.
    /// @param chainIds The list of chain IDs.
    /// @param addresses The list of addresses corresponding to the chain IDs.
    /// @dev This function is internal to allow for easier overriding and extension by derived contracts,
    ///      facilitating the reuse of peer-setting logic in different contexts.
    function _setPeers(uint256[] calldata chainIds, bytes64[] calldata addresses) internal virtual onlyOwner {
        if (chainIds.length != addresses.length) revert Errors.InvalidLength();

        for (uint256 i = 0; i < chainIds.length; ) {
            peers[chainIds[i]] = addresses[i];

            unchecked { ++i; }
        }
    }

    /// @notice Receives a cross-chain message from the Router Contract.
    ///         It is a wrapper function for the `_receiveMessage` functions, that need to be overridden.
    ///         Only the Router Contract is allowed to call this function.
    /// @param message The Equito message received.
    /// @param messageData The data of the message received.
    function receiveMessage(
        EquitoMessage calldata message,
        bytes calldata messageData
    ) external payable override onlyRouter {
        bytes64 memory peerAddress = peers[message.sourceChainSelector];
     
        if (peerAddress.lower != message.sender.lower || peerAddress.upper != message.sender.upper) {
            _receiveMessageFromNonPeer(message, messageData);
        } else {
            _receiveMessageFromPeer(message, messageData);
        }
    }

    /// @notice The logic for receiving a cross-chain message from a peer.
    /// @param message The Equito message received.
    /// @param messageData The data of the message received.
    function _receiveMessageFromPeer(
        EquitoMessage calldata message,
        bytes calldata messageData
    ) internal virtual {}

    /// @notice The logic for receiving a cross-chain message from a non-peer.
    ///         The default implementation reverts the transaction.
    /// @param message The Equito message received.
    /// @param messageData The data of the message received.
    function _receiveMessageFromNonPeer(
        EquitoMessage calldata message,
        bytes calldata messageData    
    ) internal virtual {
        revert Errors.InvalidMessageSender();
    }
}
