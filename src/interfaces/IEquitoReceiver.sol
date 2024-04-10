// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Client} from "../libraries/Client.sol";

interface IEquitoReceiver {
    function receiveMessages(Client.EquitoMessage[] calldata messages) external;
}
