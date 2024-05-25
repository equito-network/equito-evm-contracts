// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Router} from "../src/Router.sol";
import {IRouter} from "../src/interfaces/IRouter.sol";
import {CrossChainSwap} from "../src/examples/CrossChainSwap.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {EquitoMessage} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockERC20} from "../src/examples/MockERC20.sol";
import {Errors} from "../src/libraries/Errors.sol";

/// @title CrossChainSwapTest
/// @dev Test suite for the CrossChainSwap contract
contract CrossChainSwapTest is Test {
    Router router;
    CrossChainSwap swap;
    MockVerifier verifier;
    MockReceiver receiver;
    MockERC20 token0;

    address nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);

    function setUp() public {
        vm.startPrank(OWNER);
        verifier = new MockVerifier();
        receiver = new MockReceiver();
        router = new Router(1, address(verifier));
        swap = new CrossChainSwap(address(router));
        token0 = new MockERC20("Token0", "TK0", 1_000_000 ether);

        vm.deal(address(swap), 1_000 ether);
        token0.transfer(address(swap), 1_000 ether);
        vm.stopPrank();
    }

    /// @dev Tests that non-owners cannot set token prices
    function testCannotSetTokenPriceIfNotOwner() public {
        vm.prank(ALICE);
        uint256[] memory chainSelector = new uint256[](1);
        bytes[] memory destinationToken = new bytes[](1);
        uint256[] memory price = new uint256[](1);
        chainSelector[0] = 1;
        destinationToken[0] = abi.encode(nativeToken);
        price[0] = 1_000;
        vm.expectRevert();
        swap.setTokenPrice(chainSelector, destinationToken, price);
    }

    /// @dev Tests setting token prices by the owner
    function testSetTokenPrice() public {
        vm.prank(OWNER);
        uint256[] memory chainSelector = new uint256[](1);
        bytes[] memory destinationToken = new bytes[](1);
        uint256[] memory price = new uint256[](1);
        chainSelector[0] = 1;
        destinationToken[0] = abi.encode(nativeToken);
        price[0] = 1_000;
        swap.setTokenPrice(chainSelector, destinationToken, price);
        assertEq(swap.tokenPrice(1, abi.encode(nativeToken)), 1_000);
    }

    /// @dev Tests setting token prices with invalid length of inputs
    function testSetTokenPriceInvalidLength() public {
        vm.prank(OWNER);
        uint256[] memory chainSelectors = new uint256[](2);
        chainSelectors[0] = 1;
        chainSelectors[1] = 2;
        bytes[] memory destinationTokens = new bytes[](3); // Incorrect length
        destinationTokens[0] = abi.encode(address(0xAAA));
        destinationTokens[1] = abi.encode(address(0xBBB));
        destinationTokens[2] = abi.encode(address(0xCCC));
        uint256[] memory prices = new uint256[](2);
        prices[0] = 100;
        prices[1] = 200;

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidLength.selector));
        swap.setTokenPrice(chainSelectors, destinationTokens, prices);
    }

    /// @dev Tests calculating destination token amount
    function testCalculateDestinationTokenAmount() public {
        vm.prank(OWNER);
        uint256[] memory chainSelector = new uint256[](2);
        bytes[] memory destinationToken = new bytes[](2);
        uint256[] memory price = new uint256[](2);

        chainSelector[0] = 1;
        chainSelector[1] = 1;
        destinationToken[0] = abi.encode(nativeToken);
        destinationToken[1] = abi.encode(address(token0));
        price[0] = 1_000;
        price[1] = 2_000;
        swap.setTokenPrice(chainSelector, destinationToken, price);

        assertEq(
            swap.calculateDestinationTokenAmount(
                abi.encode(nativeToken),
                1_000,
                1,
                abi.encode(address(token0))
            ),
            500
        );
    }

    /// @dev Tests that non-owners cannot set swap addresses
    function testCannoSetSwapAddressIfNotOwner() public {
        vm.prank(ALICE);
        uint256[] memory chainSelectors = new uint256[](1);
        bytes[] memory swapAddresses = new bytes[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = abi.encode(address(swap));
        vm.expectRevert();
        swap.setSwapAddress(chainSelectors, swapAddresses);
    }

    /// @dev Tests setting swap addresses by the owner
    function testSetSwapAddress() public {
        vm.prank(OWNER);
        uint256[] memory chainSelectors = new uint256[](1);
        bytes[] memory swapAddresses = new bytes[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = abi.encode(address(swap));
        swap.setSwapAddress(chainSelectors, swapAddresses);
        assertEq(swap.swapAddress(1), abi.encode(address(swap)));
    }

    /// @dev Tests setting swap addresses with invalid length of inputs
    function testSetSwapAddressInvalidLength() public {
        vm.prank(OWNER);
        uint256[] memory chainSelectors = new uint256[](2);
        chainSelectors[0] = 1;
        chainSelectors[1] = 2;
        bytes[] memory swapAddresses = new bytes[](3);
        swapAddresses[0] = abi.encode(address(0xAAA));
        swapAddresses[1] = abi.encode(address(0xBBB));
        swapAddresses[2] = abi.encode(address(0xCCC));

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidLength.selector));
        swap.setSwapAddress(chainSelectors, swapAddresses);
    }

    /// @dev Tests swapping native token to ERC20
    function testSwapNativeToERC20() public {
        vm.startPrank(OWNER);

        uint256[] memory chainSelector = new uint256[](2);
        bytes[] memory destinationToken = new bytes[](2);
        uint256[] memory price = new uint256[](2);
        chainSelector[0] = 1;
        chainSelector[1] = 1;
        destinationToken[0] = abi.encode(nativeToken);
        destinationToken[1] = abi.encode(address(token0));
        price[0] = 1_000;
        price[1] = 2_000;
        swap.setTokenPrice(chainSelector, destinationToken, price);

        uint256[] memory chainSelectors = new uint256[](1);
        bytes[] memory swapAddresses = new bytes[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = abi.encode(address(swap));
        swap.setSwapAddress(chainSelectors, swapAddresses);

        vm.startPrank(ALICE);
        vm.deal(ALICE, 1_000);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(address(swap)),
            destinationChainSelector: 1,
            receiver: abi.encode(address(swap)),
            data: abi.encode(
                CrossChainSwap.TokenAmount({
                    token: abi.encode(address(token0)),
                    amount: 500,
                    recipient: abi.encode(BOB)
                })
            )
        });

        vm.expectEmit(true, true, false, true);
        emit IRouter.MessageSendRequested(address(swap), message);

        uint256 aliceBalanceBefore = ALICE.balance;
        swap.swap{value: 1_000}(
            1,
            abi.encode(address(token0)),
            abi.encode(BOB)
        );
        uint256 aliceBalanceAfter = ALICE.balance;
        assertEq(aliceBalanceBefore - aliceBalanceAfter, 1_000);

        uint256 bobBalanceBefore = token0.balanceOf(BOB);
        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;
        router.deliverAndExecuteMessages(messages, 0, bytes("0"));
        uint256 bobBalanceAfter = token0.balanceOf(BOB);
        assertEq(bobBalanceAfter - bobBalanceBefore, 500);
    }

    /// @dev Tests swapping ERC20 to native token
    function testSwapERC20ToNative() public {
        vm.startPrank(OWNER);

        uint256[] memory chainSelector = new uint256[](2);
        bytes[] memory destinationToken = new bytes[](2);
        uint256[] memory price = new uint256[](2);
        chainSelector[0] = 1;
        chainSelector[1] = 1;
        destinationToken[0] = abi.encode(nativeToken);
        destinationToken[1] = abi.encode(address(token0));
        price[0] = 1_000;
        price[1] = 2_000;
        swap.setTokenPrice(chainSelector, destinationToken, price);

        uint256[] memory chainSelectors = new uint256[](1);
        bytes[] memory swapAddresses = new bytes[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = abi.encode(address(swap));
        swap.setSwapAddress(chainSelectors, swapAddresses);

        token0.transfer(ALICE, 2_000);

        vm.startPrank(ALICE);
        token0.approve(address(swap), 1_000);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(address(swap)),
            destinationChainSelector: 1,
            receiver: abi.encode(address(swap)),
            data: abi.encode(
                CrossChainSwap.TokenAmount({
                    token: abi.encode(nativeToken),
                    amount: 2_000,
                    recipient: abi.encode(BOB)
                })
            )
        });

        vm.expectEmit(true, true, false, true);
        emit IRouter.MessageSendRequested(address(swap), message);

        uint256 aliceBalanceBefore = token0.balanceOf(ALICE);
        swap.swap(
            1,
            abi.encode(nativeToken),
            abi.encode(BOB),
            address(token0),
            1_000
        );
        uint256 aliceBalanceAfter = token0.balanceOf(ALICE);
        assertEq(aliceBalanceBefore - aliceBalanceAfter, 1_000);

        uint256 bobBalanceBefore = BOB.balance;
        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;
        router.deliverAndExecuteMessages(messages, 0, bytes("0"));
        uint256 bobBalanceAfter = BOB.balance;
        assertEq(bobBalanceAfter - bobBalanceBefore, 2_000);
    }
}