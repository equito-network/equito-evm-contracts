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

    function testCannotSetTokenPriceIfNotOwner() public {
        vm.prank(alice);
        uint256[] memory chainSelector = new uint256[](1);
        bytes[] memory destinationToken = new bytes[](1);
        uint256[] memory price = new uint256[](1);
        chainSelector[0] = 1;
        destinationToken[0] = abi.encode(nativeToken);
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
        destinationToken[0] = abi.encode(nativeToken);
        price[0] = 1 ether;
        swap.setTokenPrice(chainSelector, destinationToken, price);
        assertEq(swap.tokenPrice(1, abi.encode(nativeToken)), 1 ether);
    }

    function testCalculateDestinationTokenAmount() public {
        vm.prank(owner);
        uint256[] memory chainSelector = new uint256[](2);
        bytes[] memory destinationToken = new bytes[](2);
        uint256[] memory price = new uint256[](2);

        chainSelector[0] = 1;
        chainSelector[1] = 1;
        destinationToken[0] = abi.encode(nativeToken);
        destinationToken[1] = abi.encode(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa);
        price[0] = 1 ether;
        price[1] = 2 ether;
        swap.setTokenPrice(chainSelector, destinationToken, price);
        
        assertEq(
            swap.calculateDestinationTokenAmount(
                abi.encode(nativeToken),
                1_000,
                1,
                abi.encode(0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa)
            ),
            500
        );
    }

    function testTransferToken() public {
        // TODO
    }
}
