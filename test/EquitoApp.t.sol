// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockEquitoApp} from "./mock/MockEquitoApp.sol";
import {MockReceiver} from "./mock/MockReceiver.sol";
import {MockVerifier} from "./mock/MockVerifier.sol";
import {MockRouter} from "./mock/MockRouter.sol";
import {IEquitoVerifier} from "../src/interfaces/IEquitoVerifier.sol";
import {Errors} from "../src/libraries/Errors.sol";

/// @title EquitoAppTest
/// @dev Test suite for the EquitoApp contract
contract EquitoAppTest is Test {
    MockVerifier verifier;
    MockRouter router;
    MockEquitoApp app;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address equitoAddress = address(0x45717569746f);

    function setUp() public {
        vm.startPrank(OWNER);
        verifier = new MockVerifier();
        router = new MockRouter(
            1,
            EquitoMessageLibrary.addressToBytes64(equitoAddress)
        );
        app = new MockEquitoApp(address(router));
        vm.stopPrank();
    }

    /// @dev Tests the onlyRouter modifier
    function testOnlyRouterModifier() public {
        vm.prank(ALICE);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(app)),
            hashedData: keccak256(hex"123456")
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.InvalidRouter.selector,
                address(ALICE)
            )
        );
        app.receiveMessage(message, hex"123456");
    }

    /// @dev Tests the functionality of the setPeers function in EquitoApp contract.
    ///      It sets peer addresses for two different chain selectors and verifies that the
    ///      addresses are correctly stored by the contract.
    function testSetPeers() public {
        vm.prank(OWNER);

        uint256[] memory chainSelectors = new uint256[](2);
        chainSelectors[0] = 1;
        chainSelectors[1] = 2;

        bytes64[] memory addresses = new bytes64[](2);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(ALICE);
        addresses[1] = EquitoMessageLibrary.addressToBytes64(BOB);

        app.setPeers(chainSelectors, addresses);

        (bytes32 peer1Lower, bytes32 peer1Upper) = app.peers(1);
        (bytes32 peer2Lower, bytes32 peer2Upper) = app.peers(2);

        bytes64 memory peer1 = bytes64(peer1Lower, peer1Upper);
        bytes64 memory peer2 = bytes64(peer2Lower, peer2Upper);

        assertEq(
            EquitoMessageLibrary.bytes64ToAddress(peer1),
            ALICE,
            "Peer address for chain 1 should be ALICE"
        );
        assertEq(
            EquitoMessageLibrary.bytes64ToAddress(peer2),
            BOB,
            "Peer address for chain 2 should be BOB"
        );
    }

    /// @dev Tests receiveMessage logic with a valid peer
    function testReceiveMessageSuccess() public {
        vm.prank(OWNER);
        uint256[] memory chainSelectors = new uint256[](1);
        chainSelectors[0] = 1;

        bytes64[] memory addresses = new bytes64[](1);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(ALICE);

        app.setPeers(chainSelectors, addresses);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(app)),
            hashedData: keccak256(hex"123456")
        });

        vm.prank(address(router));
        app.receiveMessage(message, hex"123456");
    }

    /// @dev Tests the `receiveMessage` function when the peer address is zero.
    function testReceiveMessageForZeroLengthPeer() public {
        vm.prank(address(router));
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(BOB),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(app)),
            hashedData: keccak256(hex"123456")
        });

        vm.expectRevert(Errors.InvalidMessageSender.selector);
        app.receiveMessage(message, hex"123456");
    }

    /// @dev Tests the `receiveMessage` function when the sender address is not equal to the expected peer address.
    function testReceiveMessageUnequalSender() public {
        vm.prank(OWNER);
        uint256[] memory chainSelectors = new uint256[](1);
        chainSelectors[0] = 1;

        bytes64[] memory addresses = new bytes64[](1);
        addresses[0] = EquitoMessageLibrary.addressToBytes64(ALICE);

        app.setPeers(chainSelectors, addresses);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(BOB),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(address(app)),
            hashedData: keccak256(hex"123456")
        });

        vm.prank(address(router));
        vm.expectRevert(Errors.InvalidMessageSender.selector);
        app.receiveMessage(message, hex"123456");
    }

}
