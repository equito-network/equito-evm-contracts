// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";

contract MockReceiver {
    EquitoMessage public message;

    function receiveMessage(
        EquitoMessage calldata _message
    ) external {
        message = _message;
    }
}
