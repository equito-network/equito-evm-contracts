// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Router} from "../src/Router.sol";
import {CrossChainSwap} from "../src/examples/CrossChainSwap.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {EquitoMessage} from "../src/libraries/EquitoMessageLibrary.sol";
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

        token0.transfer(address(swap), 1_000 ether);
        vm.stopPrank();
    }

    function testCannotSetNativeTokenIfNotOwner() public {
        vm.prank(alice);
        uint256[] memory chainSelector = new uint256[](1);
        address[] memory tokenAddress = new address[](1);
        chainSelector[0] = 1;
        tokenAddress[0] = nativeToken;
        vm.expectRevert();
        swap.setNativeToken(chainSelector, tokenAddress);
    }

    function testSetNativeToken() public {
        vm.prank(owner);
        uint256[] memory chainSelector = new uint256[](1);
        address[] memory tokenAddress = new address[](1);
        chainSelector[0] = 1;
        tokenAddress[0] = nativeToken;
        swap.setNativeToken(chainSelector, tokenAddress);
        assertEq(swap.nativeAddress(1), nativeToken);
    }

    function testCannotSetTokenPriceIfNotOwner() public {
        vm.prank(alice);
        uint256[] memory chainSelector = new uint256[](1);
        bytes[] memory destinationToken = new bytes[](1);
        uint256[] memory price = new uint256[](1);
        chainSelector[0] = 1;
        destinationToken[0] = abi.encodePacked(nativeToken);
        price[0] = 1;
        vm.expectRevert();
        swap.setTokenPrice(chainSelector, destinationToken, price);
    }

    function testSetTokenPrice() public {
        vm.prank(owner);
        uint256[] memory chainSelector = new uint256[](1);
        bytes[] memory destinationToken = new bytes[](1);
        uint256[] memory price = new uint256[](1);
        chainSelector[0] = 1;
        destinationToken[0] = abi.encodePacked(nativeToken);
        price[0] = 1 ether;
        swap.setTokenPrice(chainSelector, destinationToken, price);
        assertEq(swap.tokenPrice(1, abi.encodePacked(nativeToken)), 1 ether);
    }

    function testCalculateDestinationTokenAmount() public {
        vm.prank(owner);
        uint256[] memory chainSelector = new uint256[](1);
        bytes[] memory destinationToken = new bytes[](1);
        uint256[] memory price = new uint256[](1);
        chainSelector[0] = 1;
        destinationToken[0] = abi.encodePacked(nativeToken);
        price[0] = 1 ether;
        swap.setTokenPrice(chainSelector, destinationToken, price);
        assertEq(
            swap.calculateDestinationTokenAmount(
                1,
                abi.encodePacked(nativeToken),
                1
            ),
            1 ether
        );
    }

    function testTransferToken() public {
        vm.startPrank(owner);
        uint256[] memory chainSelector = new uint256[](1);
        address[] memory tokenAddress = new address[](1);
        chainSelector[0] = 1;
        tokenAddress[0] = address(token0);
        swap.setNativeToken(chainSelector, tokenAddress);
        uint256[] memory chainSelector2 = new uint256[](1);
        bytes[] memory destinationToken = new bytes[](1);
        uint256[] memory price = new uint256[](1);
        chainSelector2[0] = 1;
        destinationToken[0] = abi.encodePacked(address(token0));
        price[0] = 1 ether;
        swap.setTokenPrice(chainSelector2, destinationToken, price);
        vm.startPrank(alice);
        bytes memory data = abi.encode(
            CrossChainSwap.TokenAmount({
                token: abi.encode(address(token0)),
                amount: 1,
                receiver: abi.encode(bob)
            })
        );
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(alice),
            destinationChainSelector: 1,
            receiver: abi.encode(swap),
            data: data
        });
        bytes32 newMessage = router.sendMessage(abi.encode(swap), 1, data);
        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = message;
        router.routeMessages(messages, 0, abi.encode(1));
        assertEq(token0.balanceOf(bob), 1);
        vm.stopPrank();
    }
}
