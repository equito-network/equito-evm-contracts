// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../libraries/EquitoMessage.sol";

interface IEquitoReceiver {
    function receiveMessage(EquitoMessage.EquitoMessage calldata message) external;
}
