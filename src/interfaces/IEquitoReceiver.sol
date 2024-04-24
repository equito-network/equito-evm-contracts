// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../libraries/EquitoMessageLibrary.sol";

interface IEquitoReceiver {
    function receiveMessage(EquitoMessage calldata message) external;
}
