// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Router} from "../src/Router.sol";
import {IRouter} from "../src/interfaces/IRouter.sol";
import {CrossChainSwap} from "../src/examples/CrossChainSwap.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockERC20} from "../src/examples/MockERC20.sol";

contract CrossChainSwapTest is Test {
    Router router;
    CrossChainSwap swap;
    MockVerifier verifier;
    MockReceiver receiver;
    MockERC20 token0;

    address nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address owner = address(0x03132);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        vm.startPrank(owner);
        verifier = new MockVerifier();
        router = new Router(1, address(verifier));
        swap = new CrossChainSwap(address(router));
        token0 = new MockERC20("Token0", "TK0", 1_000_000 ether);

        vm.deal(address(swap), 1_000 ether);
        token0.transfer(address(swap), 1_000 ether);
        vm.stopPrank();
    }

    /*function testCannotSetTokenPriceIfNotOwner() public {
        vm.prank(alice);
        uint256[] memory chainSelector = new uint256[](1);
        bytes[] memory destinationToken = new bytes[](1);
        uint256[] memory price = new uint256[](1);
        chainSelector[0] = 1;
        destinationToken[0] = abi.encode(nativeToken);
        price[0] = 1_000;
        vm.expectRevert();
        swap.setTokenPrice(chainSelector, destinationToken, price);
    }

    function testSetTokenPrice() public {
        vm.prank(owner);
        uint256[] memory chainSelector = new uint256[](1);
        bytes[] memory destinationToken = new bytes[](1);
        uint256[] memory price = new uint256[](1);
        chainSelector[0] = 1;
        destinationToken[0] = abi.encode(nativeToken);
        price[0] = 1_000;
        swap.setTokenPrice(chainSelector, destinationToken, price);
        assertEq(swap.tokenPrice(1, abi.encode(nativeToken)), 1_000);
    }

    function testCalculateDestinationTokenAmount() public {
        vm.prank(owner);
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

    function testCannoSetSwapAddressIfNotOwner() public {
        vm.prank(alice);
        uint256[] memory chainSelectors = new uint256[](1);
        bytes[] memory swapAddresses = new bytes[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = abi.encode(address(swap));
        vm.expectRevert();
        swap.setSwapAddress(chainSelectors, swapAddresses);
    }

    function testSetSwapAddress() public {
        vm.prank(owner);
        uint256[] memory chainSelectors = new uint256[](1);
        bytes[] memory swapAddresses = new bytes[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = abi.encode(address(swap));
        swap.setSwapAddress(chainSelectors, swapAddresses);
        assertEq(swap.swapAddress(1), abi.encode(address(swap)));
    }

    function testSwapNativeToERC20() public {
        vm.startPrank(owner);

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

        vm.startPrank(alice);
        vm.deal(alice, 1_000);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encodePacked(address(swap)),
            destinationChainSelector: 1,
            receiver: abi.encode(address(swap)),
            data: abi.encode(
                CrossChainSwap.TokenAmount({
                    token: abi.encode(address(token0)),
                    amount: 500,
                    recipient: abi.encode(bob)
                })
            )
        });

        vm.expectEmit(true, true, false, true);
        emit IRouter.MessageSendRequested(address(swap), message);

        uint256 aliceBalanceBefore = alice.balance;
        swap.swap{value: 1_000}(
            1,
            abi.encode(address(token0)),
            abi.encode(bob)
        );
        uint256 aliceBalanceAfter = alice.balance;
        assertEq(aliceBalanceBefore - aliceBalanceAfter, 1_000);

        uint256 bobBalanceBefore = token0.balanceOf(bob);
        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;
        router.routeMessages(messages, 0, bytes("0"));
        uint256 bobBalanceAfter = token0.balanceOf(bob);
        assertEq(bobBalanceAfter - bobBalanceBefore, 500);
    }*/

    function testSwapERC20ToNative() public {
        vm.startPrank(owner);

        uint256[] memory chainSelector = new uint256[](2);
        bytes[] memory destinationToken = new bytes[](2);
        uint256[] memory price = new uint256[](2);
        chainSelector[0] = 1;
        chainSelector[1] = 1;
        destinationToken[0] = abi.encode(nativeToken);  // Decode
        destinationToken[1] = abi.encodePacked(address(token0));
        price[0] = 1_000;
        price[1] = 2_000;
        swap.setTokenPrice(chainSelector, destinationToken, price);

        uint256[] memory chainSelectors = new uint256[](1);
        bytes[] memory swapAddresses = new bytes[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = abi.encodePacked(address(swap));
        swap.setSwapAddress(chainSelectors, swapAddresses);

        token0.transfer(alice, 2_000);

        vm.startPrank(alice);
        token0.approve(address(swap), 1_000);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encodePacked(address(swap)),
            destinationChainSelector: 1,
            receiver: abi.encode(address(swap)),        // Decode
            data: abi.encode(                           // Decode
                CrossChainSwap.TokenAmount({
                    token: abi.encode(nativeToken),     // Decode
                    amount: 2_000,
                    recipient: abi.encode(bob)          // Decode
                })
            )
        });

        vm.expectEmit(true, true, false, true);
        emit IRouter.MessageSendRequested(address(swap), message);
        
        console.logBytes32(EquitoMessageLibrary._hash(message));

        uint256 aliceBalanceBefore = token0.balanceOf(alice);
        swap.swap(
            1,
            abi.encode(nativeToken),
            abi.encode(bob),
            address(token0),
            1_000
        );



        
        /*uint256 aliceBalanceAfter = token0.balanceOf(alice);
        assertEq(aliceBalanceBefore - aliceBalanceAfter, 1_000);

        uint256 bobBalanceBefore = bob.balance;
        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;
        router.routeMessages(messages, 0, bytes("0"));
        uint256 bobBalanceAfter = bob.balance;
        assertEq(bobBalanceAfter - bobBalanceBefore, 2_000);*/
    }
}
