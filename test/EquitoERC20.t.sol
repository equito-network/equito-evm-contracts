// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {EquitoERC20} from "../src/EquitoERC20.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockRouter} from "./mock/MockRouter.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract EquitoERC20Test is Test {
    EquitoERC20 token;
    MockVerifier verifier;
    MockRouter router;
    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address equitoAddress = address(0x45717569746f);

    uint256 public sourceChainSelector = 1;
    uint256 public destinationChainSelector = 2;

    function setUp() public {
        vm.startPrank(OWNER);
        verifier = new MockVerifier();
        router = new MockRouter(1, address(verifier), address(verifier), EquitoMessageLibrary.addressToBytes64(equitoAddress));
        token = new EquitoERC20(address(router), "Equito Token", "EQI", 1000);

        // Mint some tokens for testing
        token.transfer(ALICE, 100);

        vm.stopPrank();
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1000);
        assertEq(token.balanceOf(OWNER), 900);
        assertEq(token.balanceOf(ALICE), 100);
    }

    function testSend() public {
        uint256 amount = 10;
        bytes64 memory receiver = EquitoMessageLibrary.addressToBytes64(BOB);

        vm.prank(ALICE);
        vm.deal(ALICE, 0.1 ether);
        token.crossChainTransfer{value: 0.1 ether}(receiver, destinationChainSelector, amount);

        assertEq(token.balanceOf(ALICE), 90);
    }

    function testReceiveToken() public {
        uint256 amount = 10;

        // Set the peer address in the contract
        vm.prank(OWNER);
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = destinationChainSelector;
        bytes64[] memory addresses = new bytes64[](1);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(address(token));
        token.setPeers(chainIds, addresses);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: block.number,
            sourceChainSelector: destinationChainSelector,
            sender: EquitoMessageLibrary.addressToBytes64(address(token)),
            destinationChainSelector: sourceChainSelector,
            receiver: EquitoMessageLibrary.addressToBytes64(address(token)),
            hashedData: keccak256(abi.encode(EquitoMessageLibrary.addressToBytes64(BOB), amount))
        });

        bytes memory messageData = abi.encode(EquitoMessageLibrary.addressToBytes64(BOB), amount);

        vm.prank(address(router));
        token.receiveMessage(message, messageData);

        assertEq(token.balanceOf(OWNER), 900);
        assertEq(token.balanceOf(BOB), amount);
    }
}