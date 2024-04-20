// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EquitoMessageLibrary} from "../libraries/EquitoMessageLibrary.sol";

interface IEquitoVerifier {
    function verifyMessages(
        EquitoMessageLibrary.EquitoMessage[] calldata messages,
        bytes calldata proof
    ) external;
}
