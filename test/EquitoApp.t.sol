// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockEquitoApp} from "./mock/MockEquitoApp.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {MockRouter} from "./mock/MockRouter.sol";
import {IEquitoVerifier} from "../src/interfaces/IEquitoVerifier.sol";
import {Errors} from "../src/libraries/Errors.sol";

/// @title EquitoAppTest
/// @dev Test suite for the EquitoApp contract
contract EquitoAppTest is Test {
    MockRouter router;
    MockEquitoApp app;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);

    function setUp() public {
        vm.startPrank(OWNER);
        router = new MockRouter();
        app = new MockEquitoApp(address(router));
        vm.stopPrank();
    }
    
    function testSendMessage() public {
        bytes memory receiverAddress = abi.encode(address(app));
        uint256 destinationChainSelector = 2;
        bytes memory data = hex"123456";

        bytes32 messageId = app.sendMessage(receiverAddress, destinationChainSelector, data);

        assertTrue(messageId != bytes32(0), "Message ID should not be zero");
    }

    /// @dev Tests the onlyRouter modifier
    function testOnlyRouterModifier() public {
        vm.prank(ALICE);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 0,
            sender: abi.encode(ALICE),
            destinationChainSelector: 2,
            receiver: abi.encode(address(app)),
            data: hex"123456"
        });
        
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidRouter.selector, address(ALICE)));
        app.receiveMessage(message);
    }

    /// @dev Tests the functionality of the setPeers function in EquitoApp contract.
    ///      It sets peer addresses for two different chain IDs and verifies that the
    ///      addresses are correctly stored by the contract.
    function testSetPeers() public {
        vm.prank(OWNER);

        uint256[] memory chainIds = new uint256[](2);
        chainIds[0] = 1;
        chainIds[1] = 2;
        
        bytes[] memory addresses = new bytes[](2);
        addresses[0] = abi.encode(ALICE);
        addresses[1] = abi.encode(BOB);

        app.setPeers(chainIds, addresses);

        bytes memory peer1 = app.peers(1);
        bytes memory peer2 = app.peers(2);

        assertEq(peer1, abi.encode(ALICE), "Peer address for chain 1 should be ALICE");
        assertEq(peer2, abi.encode(BOB), "Peer address for chain 2 should be BOB");
    }

    /// @dev Tests receiveMessage logic with a valid peer
    function testReceiveMessageSuccess() public {
        vm.prank(OWNER);
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 1;

        bytes[] memory addresses = new bytes[](1);
        addresses[0] = abi.encode(ALICE);

        app.setPeers(chainIds, addresses);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(ALICE),
            destinationChainSelector: 2,
            receiver: abi.encode(address(app)),
            data: hex"123456"
        });

        vm.prank(address(router));
        app.receiveMessage(message);
    }

    /// @dev Tests the `receiveMessage` function when the peer address is zero.
    function testReceiveMessageForZeroLengthPeer() public {
        vm.prank(address(router));
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(BOB),
            destinationChainSelector: 2,
            receiver: abi.encode(address(app)),
            data: hex"123456"
        });

        vm.expectRevert(Errors.InvalidMessageSender.selector);
        app.receiveMessage(message);
    }

    /// @dev Tests the `receiveMessage` function when the sender address is not equal to the expected peer address.
    function testReceiveMessageUnequalSender() public {
        vm.prank(OWNER);
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = 1;

        bytes[] memory addresses = new bytes[](1);
        addresses[0] = abi.encode(ALICE);

        app.setPeers(chainIds, addresses);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(BOB),
            destinationChainSelector: 2,
            receiver: abi.encode(address(app)),
            data: hex"123456"
        });

        vm.prank(address(router));
        vm.expectRevert(Errors.InvalidMessageSender.selector);
        app.receiveMessage(message);
    }
}