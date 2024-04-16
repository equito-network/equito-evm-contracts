// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../libraries/EquitoMessage.sol";

interface IEquitoVerifier {
    function verifyMessages(EquitoMessage[] calldata messages, bytes calldata proof) external; 
}
