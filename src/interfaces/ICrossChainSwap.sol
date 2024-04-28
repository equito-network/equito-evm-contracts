// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

interface ICrossChainSwap {
    error InvalidLength();
    error InvalidReceiver();

    event MessageSent(
        bytes32 indexed messageId,
        uint256 indexed destinationChainSelector,
        address receiver,
        address token,
        uint256 tokenAmount,
        address depositor
    );
}
