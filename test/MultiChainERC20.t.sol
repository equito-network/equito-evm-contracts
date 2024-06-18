// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MultiChainERC20} from "../src/examples/MultiChainERC20.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockRouter} from "./mock/MockRouter.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract MultiChainERC20Test is Test {
    MultiChainERC20 token;
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
        token = new MultiChainERC20("Equito Token", "EQI", 1000, address(router));

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
        bytes64 memory receiver = EquitoMessageLibrary.addressToBytes64(ALICE);

        vm.prank(ALICE);
        vm.deal(ALICE, 0.1 ether);
        token.send{value: 0.1 ether}(receiver, destinationChainSelector, amount);

        assertEq(token.balanceOf(ALICE), 90);
    }

    function testSendToPeer() public {
        vm.prank(OWNER);
        uint256 amount = 10;

        // Set the peer address in the contract
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = destinationChainSelector;
        bytes64[] memory addresses = new bytes64[](1);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(OWNER);
        token.setPeers(chainIds, addresses);

        vm.prank(ALICE);
        vm.deal(ALICE, 0.1 ether);
        token.sendToPeer{value: 0.1 ether}(destinationChainSelector, amount);

        assertEq(token.balanceOf(ALICE), 90);
    }

    function testReceiveTokenFromPeer() public {
        vm.prank(OWNER);

        uint256 amount = 10;
        bytes32 hashedData = keccak256(abi.encode(amount, EquitoMessageLibrary.addressToBytes64(address(token))));

        // Set the peer address in the contract
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = destinationChainSelector;
        bytes64[] memory addresses = new bytes64[](1);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(OWNER);
        token.setPeers(chainIds, addresses);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: block.number,
            sourceChainSelector: destinationChainSelector,
            sender: EquitoMessageLibrary.addressToBytes64(OWNER),
            destinationChainSelector: sourceChainSelector,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: hashedData
        });

        bytes memory messageData = abi.encode(amount, EquitoMessageLibrary.addressToBytes64(address(token)));

        vm.prank(address(router));
        token.receiveMessage(message, messageData);

        assertEq(token.balanceOf(OWNER), 900);
        assertEq(token.balanceOf(BOB), 10);
    }
}
