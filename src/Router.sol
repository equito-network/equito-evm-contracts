// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "./interfaces/IRouter.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";

contract Router is IRouter {
    IEquitoReceiver public equitoReceiver;

    constructor(address _equitoReceiver) {
        equitoReceiver = IEquitoReceiver(_equitoReceiver);
    }

    function sendMessage(
        EquitoMessage calldata message
    ) external returns (bytes32) {
        emit MessageSendRequested(msg.sender, message);
        // !TODO: Implement the sendMessage function.
        return keccak256(abi.encodePacked(""));
    }

    function routeMessages() external {
        // !TODO: Implement route messages function.
    }
}
