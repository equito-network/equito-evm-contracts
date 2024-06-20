// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Router} from "../src/Router.sol";
import {IRouter} from "../src/interfaces/IRouter.sol";
import {IEquitoFees} from "../src/interfaces/IEquitoFees.sol";
import {CrossChainSwap} from "../src/examples/CrossChainSwap.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {MockEquitoFees} from "./mock/MockEquitoFees.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockERC20} from "../src/examples/MockERC20.sol";
import {Errors} from "../src/libraries/Errors.sol";

/// @title CrossChainSwapTest
/// @dev Test suite for the CrossChainSwap contract
contract CrossChainSwapTest is Test {
    Router router;
    CrossChainSwap swap;
    MockVerifier verifier;
    MockReceiver receiver;
    MockEquitoFees equitoFees;
    MockERC20 token0;

    address nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address equitoAddress = address(0x45717569746f);

    uint256 constant INITIAL_FEE = 0.1 ether;

    function setUp() public {
        vm.startPrank(OWNER);
        verifier = new MockVerifier();
        equitoFees = new MockEquitoFees();
        receiver = new MockReceiver();
        router = new Router(
            1,
            address(verifier),
            address(equitoFees),
            EquitoMessageLibrary.addressToBytes64(equitoAddress)
        );
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
        bytes64[] memory swapAddresses = new bytes64[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = EquitoMessageLibrary.addressToBytes64(address(swap));
        vm.expectRevert();
        swap.setSwapAddress(chainSelectors, swapAddresses);
    }

    /// @dev Tests setting swap addresses by the owner
    function testSetSwapAddress() public {
        vm.prank(OWNER);
        uint256[] memory chainSelectors = new uint256[](1);
        bytes64[] memory swapAddresses = new bytes64[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = EquitoMessageLibrary.addressToBytes64(address(swap));
        swap.setSwapAddress(chainSelectors, swapAddresses);

        (bytes32 lower, bytes32 upper) = swap.peers(1);
        assertEq(lower, swapAddresses[0].lower);
        assertEq(upper, swapAddresses[0].upper);
    }

    /// @dev Tests setting swap addresses with invalid length of inputs
    function testSetSwapAddressInvalidLength() public {
        vm.prank(OWNER);
        uint256[] memory chainSelectors = new uint256[](2);
        chainSelectors[0] = 1;
        chainSelectors[1] = 2;
        bytes64[] memory swapAddresses = new bytes64[](3);
        swapAddresses[0] = EquitoMessageLibrary.addressToBytes64(
            address(0xAAA)
        );
        swapAddresses[1] = EquitoMessageLibrary.addressToBytes64(
            address(0xBBB)
        );
        swapAddresses[2] = EquitoMessageLibrary.addressToBytes64(
            address(0xCCC)
        );

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidLength.selector));
        swap.setSwapAddress(chainSelectors, swapAddresses);
    }

    /// @dev Tests swapping native token to ERC20 when insufficient value sent
    function testSwapNativeToERC20InsufficientValueSent() public payable {
        vm.startPrank(ALICE);
        vm.deal(ALICE, INITIAL_FEE + 1_000);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.InsufficientValueSent.selector)
        );
        swap.swap{value: 500}(
            1,
            abi.encode(address(token0)),
            abi.encode(BOB),
            1_000
        );
    }

    /// @dev Tests swapping native token to ERC20
    function testSwapNativeToERC20() public payable {
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
        bytes64[] memory swapAddresses = new bytes64[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = EquitoMessageLibrary.addressToBytes64(address(swap));
        swap.setSwapAddress(chainSelectors, swapAddresses);

        vm.startPrank(ALICE);
        vm.deal(ALICE, INITIAL_FEE + 1_000);

        CrossChainSwap.TokenAmount memory data = CrossChainSwap.TokenAmount({
            token: abi.encode(address(token0)),
            amount: 500,
            recipient: abi.encode(BOB)
        });

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(address(swap)),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(swap)),
            hashedData: keccak256(abi.encode(data))
        });

        vm.expectEmit(true, true, false, true);
        emit IEquitoFees.FeePaid(address(swap), INITIAL_FEE);

        vm.expectEmit(true, true, false, true);
        emit IRouter.MessageSendRequested(message, abi.encode(data));

        uint256 aliceBalanceBefore = ALICE.balance;
        swap.swap{value: INITIAL_FEE + 1_000}(
            1,
            abi.encode(address(token0)),
            abi.encode(BOB),
            1_000
        );
        uint256 aliceBalanceAfter = ALICE.balance;

        assertEq(aliceBalanceBefore, INITIAL_FEE + 1_000);
        assertEq(aliceBalanceAfter, 0);

        uint256 bobBalanceBefore = token0.balanceOf(BOB);
        router.deliverAndExecuteMessage(
            message,
            abi.encode(data),
            0,
            bytes("0")
        );
        uint256 bobBalanceAfter = token0.balanceOf(BOB);
        assertEq(bobBalanceBefore, 0);
        assertEq(bobBalanceAfter, 500);
    }

    /// @dev Tests swapping ERC20 to native token
    function testSwapERC20ToNative() public payable {
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
        bytes64[] memory swapAddresses = new bytes64[](1);
        chainSelectors[0] = 1;
        swapAddresses[0] = EquitoMessageLibrary.addressToBytes64(address(swap));
        swap.setSwapAddress(chainSelectors, swapAddresses);

        token0.transfer(ALICE, 2_000);

        vm.startPrank(ALICE);
        vm.deal(ALICE, INITIAL_FEE);

        token0.approve(address(swap), 1_000);

        CrossChainSwap.TokenAmount memory data = CrossChainSwap.TokenAmount({
            token: abi.encode(nativeToken),
            amount: 2_000,
            recipient: abi.encode(BOB)
        });

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(address(swap)),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(swap)),
            hashedData: keccak256(abi.encode(data))
        });

        vm.expectEmit(true, true, false, true);
        emit IEquitoFees.FeePaid(address(swap), INITIAL_FEE);

        vm.expectEmit(true, true, false, true);
        emit IRouter.MessageSendRequested(message, abi.encode(data));

        uint256 aliceBalanceBefore = token0.balanceOf(ALICE);
        swap.swap{value: INITIAL_FEE}(
            1,
            abi.encode(nativeToken),
            abi.encode(BOB),
            address(token0),
            1_000
        );
        uint256 aliceBalanceAfter = token0.balanceOf(ALICE);
        assertEq(aliceBalanceBefore, 2_000);
        assertEq(aliceBalanceAfter, 1_000);

        uint256 bobBalanceBefore = BOB.balance;
        router.deliverAndExecuteMessage(
            message,
            abi.encode(data),
            0,
            bytes("0")
        );
        uint256 bobBalanceAfter = BOB.balance;
        assertEq(bobBalanceBefore, 0);
        assertEq(bobBalanceAfter, 2000);
    }
}
