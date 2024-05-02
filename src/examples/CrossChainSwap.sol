// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";

import {EquitoApp} from "../EquitoApp.sol";
import {EquitoMessage} from "../libraries/EquitoMessageLibrary.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";

/// Example contract that demonstrates how to swap tokens between different chains using Equito.
contract CrossChainSwap is EquitoApp, Ownable {
    error InvalidLength();

    event SwapRequested(
        bytes32 indexed messageId,
        uint256 indexed destinationChainSelector,
        address sourceToken,
        uint256 sourceAmount,
        bytes destinationToken,
        uint256 destinationAmount,
        bytes recipient
    );

    /// We use this address to represent our native token.
    address internal constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// The EquitoReceiver contract address on the destination chain.
    mapping(uint256 => bytes) public swapAddress;

    /// The prices of the various supported tokens on each chain.
    /// The first mapping is the chain selector, and the second mapping is the token address.
    mapping(uint256 => mapping(bytes => uint256)) public tokenPrice;

    constructor(address _router) EquitoApp(_router) Ownable(msg.sender) {}

    struct TokenAmount {
        bytes token;
        uint256 amount;
        bytes recipient;
    }

    /// Helper function to calculate the destination token amount,
    /// given a certain amount of source token, and the destination token.
    function calculateDestinationTokenAmount(
        bytes memory sourceToken,
        uint256 amount,
        uint256 destinationChainSelector,
        bytes memory destinationToken
    ) public view returns (uint256) {
        IRouter router = IRouter(router);

        return
            (amount * tokenPrice[router.chainSelector()][sourceToken]) /
            tokenPrice[destinationChainSelector][destinationToken];
    }

    /// Update the addresses of the EquitoReceiver contracts on the destination chains.
    function setSwapAddress(
        uint256[] memory chainSelectors,
        bytes[] memory swapAddresses
    ) external onlyOwner {
        if (chainSelectors.length != swapAddresses.length)
            revert InvalidLength();
        for (uint256 i = 0; i < chainSelectors.length; i++) {
            swapAddress[chainSelectors[i]] = swapAddresses[i];
        }
    }

    /// Update the prices of the various supported tokens on different chains.
    function setTokenPrice(
        uint256[] memory chainSelectors,
        bytes[] memory destinationTokens,
        uint256[] memory prices
    ) external onlyOwner {
        if (
            chainSelectors.length != prices.length ||
            prices.length != destinationTokens.length
        ) revert InvalidLength();
        for (uint256 i = 0; i < chainSelectors.length; i++) {
            tokenPrice[chainSelectors[i]][destinationTokens[i]] = prices[i];
        }
    }

    /// Override the _receiveMessage function of IEquitoReceiver to handle the received messages.
    /// In this case, we transfer the tokens to the appropriate recipient account.
    function _receiveMessage(EquitoMessage calldata message) internal override {
        TokenAmount memory tokenAmount = abi.decode(
            message.data,
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

    /// Swap a certain amount of ERC20 token from the source chain to any token on the destination chain.
    function swap(
        uint256 destinationChainSelector,
        bytes calldata destinationToken,
        bytes calldata recipient,
        address sourceToken,
        uint256 amount
    ) external {
        TransferHelper.safeTransferFrom(
            sourceToken,
            msg.sender,
            address(this),
            amount
        );

        _swap(
            sourceToken,
            amount,
            destinationChainSelector,
            destinationToken,
            recipient
        );
    }

    /// Swap a certain amount of native token from the source chain to any token on the destination chain.
    function swap(
        uint256 destinationChainSelector,
        bytes calldata destinationToken,
        bytes calldata recipient
    ) external payable {
        _swap(
            NATIVE_TOKEN,
            msg.value,
            destinationChainSelector,
            destinationToken,
            recipient
        );
    }

    /// Internal function that handles the swapping of tokens between chains.
    /// It sends a message to the cross-chain router to initiate the swap.
    /// It assumes that the correct amount of sourceToken has already been received by the contract.
    function _swap(
        address sourceToken,
        uint256 sourceAmount,
        uint256 destinationChainSelector,
        bytes calldata destinationToken,
        bytes calldata recipient
    ) internal returns (bytes32 messageId) {
        // Calculate the destination token amount
        uint256 destinationAmount = calculateDestinationTokenAmount(
            abi.encode(sourceToken),
            sourceAmount,
            destinationChainSelector,
            destinationToken
        );

        // Initialize a router client instance to interact with cross-chain router
        IRouter router = IRouter(router);

        TokenAmount memory tokenAmount = TokenAmount({
            token: destinationToken,
            amount: destinationAmount,
            recipient: recipient
        });

        // Send the message through the router and store the returned message ID
        messageId = router.sendMessage(
            swapAddress[destinationChainSelector],
            destinationChainSelector,
            abi.encode(tokenAmount)
        );

        // Emit an event with message details
        emit SwapRequested(
            messageId,
            destinationChainSelector,
            sourceToken,
            sourceAmount,
            destinationToken,
            destinationAmount,
            recipient
        );

        // Return the message ID
        return messageId;
    }
}
