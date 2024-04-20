// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessageLibrary} from "../libraries/EquitoMessageLibrary.sol";

interface IEquitoReceiver {
    function receiveMessage(
        EquitoMessageLibrary.EquitoMessage calldata message
    ) external;
}
