// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "../../src/Router.sol";
import {EquitoTokenApp} from "../../src/EquitoTokenApp.sol";
import {EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {bytes64} from "../../src/libraries/EquitoMessageLibrary.sol";
import {Errors} from "../../src/libraries/Errors.sol";
import {Test, console} from "forge-std/Test.sol";

contract MockEquitoTokenApp is EquitoTokenApp {
    /// @notice Event to track received token transfers.
    event TokenReceived(address indexed sender, uint256 amount, bytes64 tokenAddress, uint256 chainId);

    /// @notice Event to track received token transfers from non-peer.
    event NonPeerTokenReceived(address indexed sender, uint256 amount, bytes64 tokenAddress, uint256 chainId);

    constructor(address _router) EquitoTokenApp(_router) {}

    /// @notice Mock implementation for handling token transfers from a peer.
    /// @param message The Equito message received.
    /// @param amount The amount of tokens transferred.
    /// @param tokenAddress The address of the token contract.
    function _receiveTokenFromPeer(
        EquitoMessage calldata message,
        uint256 amount,
        bytes64 memory tokenAddress
    ) internal override {
        emit TokenReceived(msg.sender, amount, tokenAddress, message.sourceChainSelector);
    }
}