// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";

import {EquitoApp} from "../EquitoApp.sol";
import {EquitoMessage} from "../libraries/EquitoMessageLibrary.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";

contract CrossChainSwap is EquitoApp, Ownable {
    error InvalidLength();
    error InvalidReceiver();

    event SwapRequested(
        bytes32 indexed messageId,
        uint256 indexed destinationChainSelector,
        address receiver,
        address token,
        uint256 tokenAmount,
        bytes tokenReceiver
    );

    address internal constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(uint256 => address) public nativeAddress;
    mapping(uint256 => uint256) public nativePrice;

    constructor(address _router) EquitoApp(_router) Ownable(msg.sender) {}

    struct TokenAmount {
        address token;
        uint256 amount;
        bytes receiver;
    }

    function calculateDestinationTokenAmount(
        uint256 destinationChainSelector,
        address destinationToken,
        uint256 amount
    ) public view returns (uint256) {
        if (destinationToken == NATIVE_TOKEN) {
            return amount * nativePrice[destinationChainSelector];
        } else {
            return amount;
        }
    }

    function setNativeToken(
        uint256[] memory chainSelector,
        address[] memory tokenAddress
    ) external onlyOwner {
        if (chainSelector.length != tokenAddress.length) revert InvalidLength();
        for (uint256 i = 0; i < chainSelector.length; i++) {
            nativeAddress[chainSelector[i]] = tokenAddress[i];
        }
    }

    function setNativePrice(
        uint256[] memory chainSelector,
        uint256[] memory price
    ) external onlyOwner {
        if (chainSelector.length != price.length) revert InvalidLength();
        for (uint256 i = 0; i < chainSelector.length; i++) {
            nativePrice[chainSelector[i]] = price[i];
        }
    }

    function _receiveMessage(EquitoMessage calldata message) internal override {
        TokenAmount memory tokenAmount = abi.decode(
            message.data,
            (TokenAmount)
        );

        releaseToken(
            tokenAmount.receiver,
            tokenAmount.token,
            tokenAmount.amount
        );
    }

    function releaseToken(
        bytes memory receiver,
        address token,
        uint256 amount
    ) private {
        address tokenReceiver = abi.decode(receiver, (address));
        if (token == NATIVE_TOKEN) {
            TransferHelper.safeTransferETH(tokenReceiver, amount);
        } else {
            TransferHelper.safeTransfer(token, tokenReceiver, amount);
        }
    }

    function lockToken(
        uint256 destinationChainSelector,
        address destinationToken,
        address sourceToken,
        uint256 amount,
        address receiver,
        bytes memory tokenReceiver
    ) external {
        TransferHelper.safeTransferFrom(
            sourceToken,
            msg.sender,
            address(this),
            amount
        );

        uint256 newAmount = calculateDestinationTokenAmount(
            destinationChainSelector,
            destinationToken,
            amount
        );

        transferTokens(
            destinationChainSelector,
            receiver,
            destinationToken,
            newAmount,
            tokenReceiver
        );
    }

    function lockERC20(
        uint256 destinationChainSelector,
        address destinationToken,
        address receiver,
        bytes memory tokenReceiver
    ) external payable {
        uint256 newAmount = calculateDestinationTokenAmount(
            destinationChainSelector,
            NATIVE_TOKEN,
            msg.value
        );

        transferTokens(
            destinationChainSelector,
            receiver,
            destinationToken,
            newAmount,
            tokenReceiver
        );
    }

    function transferTokens(
        uint256 destinationChainSelector,
        address receiver,
        address token,
        uint256 amount,
        bytes memory tokenReceiver
    ) public returns (bytes32 messageId) {
        if (receiver == address(0)) revert InvalidReceiver();

        // Initialize a router client instance to interact with cross-chain router
        IRouter router = IRouter(router);

        TokenAmount memory tokenAmount = TokenAmount({
            token: token,
            amount: amount,
            receiver: tokenReceiver
        });

        // Send the message through the router and store the returned message ID
        messageId = router.sendMessage(
            abi.encode(receiver),
            destinationChainSelector,
            abi.encode(tokenAmount)
        );

        // Emit an event with message details
        emit SwapRequested(
            messageId,
            destinationChainSelector,
            receiver,
            token,
            amount,
            tokenReceiver
        );

        // Return the message ID
        return messageId;
    }
}
