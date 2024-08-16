// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoApp} from "../EquitoApp.sol";
import {bytes64, EquitoMessage} from "../libraries/EquitoMessageLibrary.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title CrossChainSwap
/// @notice This contract facilitates token swaps between different blockchains using the Equito protocol.
contract CrossChainSwap is EquitoApp {
    /// @notice Event emitted when a token swap is requested.
    /// @param messageHash The unique identifier for the message.
    /// @param destinationChainSelector The identifier of the destination blockchain.
    /// @param sourceToken The address of the source token.
    /// @param sourceAmount The amount of source tokens to be swapped.
    /// @param destinationToken The address of the destination token.
    /// @param destinationAmount The amount of destination tokens to be received.
    /// @param recipient The address of the recipient on the destination chain.
    event SwapRequested(
        bytes32 indexed messageHash,
        uint256 indexed destinationChainSelector,
        address sourceToken,
        uint256 sourceAmount,
        bytes destinationToken,
        uint256 destinationAmount,
        bytes recipient
    );

    /// @dev The address used to represent the native token.
    address internal constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Mapping to store the prices of supported tokens on different chains.
    /// @dev The first key is the chain selector, and the second key is the token address.
    mapping(uint256 => mapping(bytes => uint256)) public tokenPrice;

    /// @notice Constructor to initialize the CrossChainSwap contract.
    /// @param _router The address of the router contract.
    constructor(address _router) payable EquitoApp(_router) {}

    /// @notice Struct to store token amount information.
    /// @param token The address of the token.
    /// @param amount The amount of the token.
    /// @param recipient The address of the recipient.
    struct TokenAmount {
        bytes token;
        uint256 amount;
        bytes recipient;
    }

    /// @notice Calculate the destination token amount given the source token amount and destination token.
    /// @param sourceToken The address of the source token.
    /// @param amount The amount of source tokens.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param destinationToken The address of the destination token.
    /// @return The calculated amount of destination tokens.
    function calculateDestinationTokenAmount(
        bytes memory sourceToken,
        uint256 amount,
        uint256 destinationChainSelector,
        bytes memory destinationToken
    ) public view returns (uint256) {
        return
            (amount * tokenPrice[router.chainSelector()][sourceToken]) /
            tokenPrice[destinationChainSelector][destinationToken];
    }

    /// @notice Update the addresses of the EquitoReceiver contracts on the destination chains.
    /// @param chainSelectors The list of chain selectors.
    /// @param swapAddresses The list of swap addresses corresponding to the chain selectors.
    function setSwapAddress(
        uint256[] calldata chainSelectors,
        bytes64[] calldata swapAddresses
    ) external onlyOwner {
        _setPeers(chainSelectors, swapAddresses);
    }

    /// @notice Update the prices of supported tokens on different chains.
    /// @param chainSelectors The list of chain selectors.
    /// @param destinationTokens The list of destination token addresses.
    /// @param prices The list of prices corresponding to the destination tokens.
    function setTokenPrice(
        uint256[] memory chainSelectors,
        bytes[] memory destinationTokens,
        uint256[] memory prices
    ) external onlyOwner {
        if (
            chainSelectors.length != prices.length ||
            prices.length != destinationTokens.length
        ) revert Errors.InvalidLength();
        for (uint256 i = 0; i < chainSelectors.length; i++) {
            tokenPrice[chainSelectors[i]][destinationTokens[i]] = prices[i];
        }
    }

    /// @notice Handle the received messages from peers.
    /// Since we know the message comes from a valid sender,
    /// we transfer the tokens to the appropriate recipient account.
    /// @param message The Equito message received.
    function _receiveMessageFromPeer(
        EquitoMessage calldata message, 
        bytes calldata messageData
    ) internal override {
        TokenAmount memory tokenAmount = abi.decode(
            messageData,
            (TokenAmount)
        );

        address recipient = abi.decode(tokenAmount.recipient, (address));
        address token = abi.decode(tokenAmount.token, (address));
        if (token == NATIVE_TOKEN) {
            TransferHelper.safeTransferETH(recipient, tokenAmount.amount);
        } else {
            TransferHelper.safeTransfer(token, recipient, tokenAmount.amount);
        }
    }

    /// @notice Swap ERC20 tokens from the source chain to any token on the destination chain.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param destinationToken The address of the destination token.
    /// @param recipient The address of the recipient on the destination chain.
    /// @param sourceToken The address of the source token.
    /// @param amount The amount of source tokens to swap.
    function swap(
        uint256 destinationChainSelector,
        bytes calldata destinationToken,
        bytes calldata recipient,
        address sourceToken,
        uint256 amount
    ) external payable {
        TransferHelper.safeTransferFrom(
            sourceToken,
            msg.sender,
            address(this),
            amount
        );

        _swap(
            sourceToken,
            amount,
            msg.value,
            destinationChainSelector,
            destinationToken,
            recipient
        );
    }

    /// @notice Swap native tokens from the source chain to any token on the destination chain.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param destinationToken The address of the destination token.
    /// @param recipient The address of the recipient on the destination chain.
    /// @param amount The amount of native tokens to swap.
    function swap(
        uint256 destinationChainSelector,
        bytes calldata destinationToken,
        bytes calldata recipient,
        uint256 amount
    ) external payable {
        if (amount > msg.value) {
            revert Errors.InsufficientValueSent();
        }

        uint256 fee = msg.value - amount;

        _swap(
            NATIVE_TOKEN,
            amount,
            fee,
            destinationChainSelector,
            destinationToken,
            recipient
        );
    }

    /// @dev Internal function to handle token swaps between chains.
    /// It sends a message to the cross-chain router to initiate the swap.
    /// It assumes that the correct amount of sourceToken has already been received by the contract.
    /// @param sourceToken The address of the source token.
    /// @param sourceAmount The amount of source tokens.
    /// @param fee The amount of the fee to be paid.
    /// @param destinationChainSelector The identifier of the destination chain.
    /// @param destinationToken The address of the destination token.
    /// @param recipient The address of the recipient on the destination chain.
    /// @return messageHash The unique identifier for the message.
    function _swap(
        address sourceToken,
        uint256 sourceAmount,
        uint256 fee,
        uint256 destinationChainSelector,
        bytes calldata destinationToken,
        bytes calldata recipient
    ) internal returns (bytes32 messageHash) {
        // Calculate the destination token amount
        uint256 destinationAmount = calculateDestinationTokenAmount(
            abi.encode(sourceToken),
            sourceAmount,
            destinationChainSelector,
            destinationToken
        );

        TokenAmount memory tokenAmount = TokenAmount({
            token: destinationToken,
            amount: destinationAmount,
            recipient: recipient
        });

        // Send the message through the router and store the returned message ID
        messageHash = router.sendMessage{value: fee}(
            getPeer(destinationChainSelector),
            destinationChainSelector,
            abi.encode(tokenAmount)
        );

        // Emit an event with message details
        emit SwapRequested(
            messageHash,
            destinationChainSelector,
            sourceToken,
            sourceAmount,
            destinationToken,
            destinationAmount,
            recipient
        );

        // Return the message ID
        return messageHash;
    }
}
