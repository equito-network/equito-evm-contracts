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

    address constant ALICE = address(0xA11CE);

    function setUp() public {
        router = new MockRouter();
        app = new MockEquitoApp(address(router));
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
            sourceChainSelector: 1,
            sender: abi.encode(ALICE),
            destinationChainSelector: 2,
            receiver: abi.encode(address(app)),
            data: hex"123456"
        });
        
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidRouter.selector, address(ALICE)));
        app.receiveMessage(message);
    }
}
