// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockEquitoTokenApp} from "./mock/MockEquitoTokenApp.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockRouter} from "./mock/MockRouter.sol";
import {IEquitoVerifier} from "../src/interfaces/IEquitoVerifier.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract EquitoTokenAppTest is Test {
    MockVerifier verifier;
    MockEquitoTokenApp public app;
    MockRouter public router;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address equitoAddress = address(0x45717569746f);
    address sourceEquitoAddress = address(0x45717569746f2031);
    address destinationEquitoAddress = address(0x45717569746f2032);
    address eqiToken = address(0x455149);


    uint256 public sourceChainSelector = 1;
    uint256 public destinationChainSelector = 2;
    bytes64 public tokenAddress = EquitoMessageLibrary.addressToBytes64(eqiToken);
    uint256 public amount = 100;

    event TokenReceived(address indexed sender, uint256 amount, bytes64 tokenAddress, uint256 chainId);
    event NonPeerTokenReceived(address indexed sender, uint256 amount, bytes64 tokenAddress, uint256 chainId);

    function setUp() public {
        vm.startPrank(OWNER);
        verifier = new MockVerifier();
        router = new MockRouter(1, address(verifier), address(verifier), EquitoMessageLibrary.addressToBytes64(equitoAddress));
        app = new MockEquitoTokenApp(address(router));

        uint256[] memory chainIds = new uint256[](2);
        chainIds[0] = sourceChainSelector;
        chainIds[1] = destinationChainSelector;

        bytes64[] memory addresses = new bytes64[](2);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(sourceEquitoAddress);
        addresses[1] = EquitoMessageLibrary.addressToBytes64(destinationEquitoAddress);

        app.setPeers(chainIds, addresses);

        vm.stopPrank();
    }

    function testSendToken() public {
        bytes32 messageId = app.sendToken{value: 0.1 ether}(EquitoMessageLibrary.addressToBytes64(destinationEquitoAddress), destinationChainSelector, amount, tokenAddress);
        assertTrue(messageId != bytes32(0));
    }

    function testSendTokenToPeer() public {
        bytes32 messageId = app.sendTokenToPeer{value: 0.1 ether}(destinationChainSelector, amount, tokenAddress);
        assertTrue(messageId != bytes32(0));
    }

    function testSendTokenToInvalidPeer() public {
        uint256 invalidChainSelector = 99;

        vm.expectRevert(
            Errors.InvalidPeerAddress.selector
        );
        bytes32 messageId = app.sendTokenToPeer{value: 0.1 ether}(invalidChainSelector, amount, tokenAddress);
    }

    function testReceiveTokenFromPeer() public {
        EquitoMessage memory message = EquitoMessage({
            blockNumber: block.number,
            sourceChainSelector: destinationChainSelector,
            sender: EquitoMessageLibrary.addressToBytes64(destinationEquitoAddress),
            destinationChainSelector: sourceChainSelector,
            receiver: EquitoMessageLibrary.addressToBytes64(sourceEquitoAddress),
            hashedData: keccak256(abi.encode(amount, tokenAddress))
        });

        bytes memory messageData = abi.encode(destinationChainSelector, EquitoMessageLibrary.addressToBytes64(destinationEquitoAddress), amount, tokenAddress);

        vm.expectEmit(true, true, true, true);
        emit TokenReceived(address(router), amount, tokenAddress, destinationChainSelector);

        vm.prank(address(router));
        app.receiveMessage(message, messageData);
    }


    function testReceiveTokenFromNonPeerReverts() public {
        address nonPeerAddress = address(0x4e6f6e2050656572);
        EquitoMessage memory message = EquitoMessage({
            blockNumber: block.number,
            sourceChainSelector: destinationChainSelector,
            sender: EquitoMessageLibrary.addressToBytes64(nonPeerAddress),
            destinationChainSelector: sourceChainSelector,
            receiver: EquitoMessageLibrary.addressToBytes64(sourceEquitoAddress),
            hashedData: keccak256(abi.encode(amount, tokenAddress))
        });

        bytes memory messageData = abi.encode(destinationChainSelector, EquitoMessageLibrary.addressToBytes64(nonPeerAddress), amount, tokenAddress);
        vm.expectRevert(Errors.InvalidMessageSender.selector);

        vm.prank(address(router));
        app.receiveMessage(message, messageData);
    }
}