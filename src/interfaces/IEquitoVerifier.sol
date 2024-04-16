// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

<<<<<<< HEAD
import {EquitoMessage} from "../libraries/EquitoMessageLibrary.sol";
=======
import {EquitoMessage} from "../libraries/EquitoMessage.sol";
>>>>>>> dbffd6a (`IEquitoVerifier` interface)

interface IEquitoVerifier {
    function verifyMessages(EquitoMessage[] calldata messages, bytes calldata proof) external; 
}
