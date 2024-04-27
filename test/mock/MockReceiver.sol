// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {IEquitoReceiver} from "../../src/interfaces/IEquitoReceiver.sol";

contract MockReceiver is IEquitoReceiver {
    EquitoMessage public message;

    function receiveMessage(EquitoMessage calldata _message) external override {
        message = _message;
    }

    function getMessage() public view returns (EquitoMessage memory) {
        return message;
    }
}
