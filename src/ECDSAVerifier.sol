// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IEquitoVerifier} from "./interfaces/IEquitoVerifier.sol";
import {EquitoMessage} from "./libraries/EquitoMessage.sol";

contract ECDSAVerifier is IEquitoVerifier {
    function verifyMessages(
        EquitoMessage.EquitoMessage[] calldata messages,
        bytes calldata proof
    ) external override {
        // Verify the messages
    }
}
