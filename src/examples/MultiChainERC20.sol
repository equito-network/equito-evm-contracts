// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EquitoTokenApp} from "../EquitoTokenApp.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../libraries/EquitoMessageLibrary.sol";

contract MultiChainERC20 is ERC20, EquitoTokenApp {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address _router
    ) ERC20(name, symbol) EquitoTokenApp(_router) {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Sends tokens to a specified address on another chain.
    /// @param receiver The address of the receiver on the destination chain.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param amount The amount of tokens to send.
    function send(
        bytes64 calldata receiver,
        uint256 destinationChainSelector,
        uint256 amount
    ) external payable {
        _burn(msg.sender, amount);
        bytes64 memory tokenAddress = EquitoMessageLibrary.addressToBytes64(address(this));
        this.sendToken(receiver, destinationChainSelector, amount, tokenAddress);
    }

    /// @notice Sends tokens to a peer on another chain.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param amount The amount of tokens to send.
    function sendToPeer(
        uint256 destinationChainSelector,
        uint256 amount
    ) external payable {
        _burn(msg.sender, amount);
        bytes64 memory tokenAddress = EquitoMessageLibrary.addressToBytes64(address(this));

        this.sendTokenToPeer(destinationChainSelector, amount, tokenAddress);
    }

    /// @notice Handles the reception of a token transfer message from a peer.
    /// @param message The Equito message received.
    /// @param amount The amount of tokens transferred.
    /// @param tokenAddress The address of the token contract.
    function _receiveTokenFromPeer(
        EquitoMessage calldata message,
        uint256 amount,
        bytes64 memory tokenAddress
    ) internal override {
        address recipient = EquitoMessageLibrary.bytes64ToAddress(message.receiver);
        _mint(recipient, amount);
    }
}
