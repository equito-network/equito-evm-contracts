// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../../src/libraries/EquitoMessage.sol";

contract MockReceiver {
    EquitoMessage.EquitoMessage public message;

    function receiveMessage(
        EquitoMessage.EquitoMessage calldata _message
    ) external {
        message = _message;
    }
}
