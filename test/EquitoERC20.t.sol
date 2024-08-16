// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {EquitoERC20} from "../src/EquitoERC20.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockEquitoFees} from "./mock/MockEquitoFees.sol";
import {Router} from "../src/Router.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract EquitoERC20Test is Test {
    EquitoERC20 token;
    MockVerifier verifier;
    MockEquitoFees fees;
    Router router;
    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address equitoAddress = address(0x45717569746f);

    function setUp() public {
        vm.startPrank(OWNER);
        verifier = new MockVerifier();
        fees = new MockEquitoFees();
        router = new Router(
            1,
            address(verifier),
            address(fees),
            EquitoMessageLibrary.addressToBytes64(equitoAddress)
        );
        token = new EquitoERC20(address(router), "Equito Token", "EQI", 1000);
        
        uint256[] memory chainSelectors = new uint256[](1);
        chainSelectors[0] = 1;

        bytes64[] memory addresses = new bytes64[](1);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(address(token));

        token.setPeers(chainSelectors, addresses);

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
        token.crossChainTransfer{value: 0.1 ether}(
            receiver,
            1,
            amount
        );

        assertEq(token.balanceOf(ALICE), 90);
    }

    function testReceiveToken() public {
        uint256 amount = 10;

        EquitoMessage memory message = EquitoMessage({
            blockNumber: block.number,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(address(token)),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(token)),
            hashedData: keccak256(
                abi.encode(EquitoMessageLibrary.addressToBytes64(BOB), amount)
            )
        });

        bytes memory messageData = abi.encode(
            EquitoMessageLibrary.addressToBytes64(BOB),
            amount
        );

        vm.prank(address(router));
        token.receiveMessage(message, messageData);

        assertEq(token.balanceOf(OWNER), 900);
        assertEq(token.balanceOf(BOB), amount);
    }
}
