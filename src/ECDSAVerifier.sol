// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IEquitoVerifier} from "./interfaces/IEquitoVerifier.sol";
import {EquitoMessageLibrary} from "./libraries/EquitoMessageLibrary.sol";

contract ECDSAVerifier is IEquitoVerifier {
    function verifyMessages(
        EquitoMessageLibrary.EquitoMessage[] calldata messages,
        bytes calldata proof
    ) external override {
        // Verify the messages
    }
}
