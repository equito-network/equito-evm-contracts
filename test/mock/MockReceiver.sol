// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {IEquitoReceiver} from "../../src/interfaces/IEquitoReceiver.sol";

contract MockReceiver is IEquitoReceiver {
    EquitoMessage public message;
    bytes public messageData;

    function receiveMessage(
        EquitoMessage calldata _message, 
        bytes calldata _messageData
    ) external payable override {
        message = _message;
        messageData = _messageData;
    }

    function getMessage() public view returns (EquitoMessage memory) {
        return message;
    }

    function getMessageData() public view returns (bytes memory) {
        return messageData;
    }
}
