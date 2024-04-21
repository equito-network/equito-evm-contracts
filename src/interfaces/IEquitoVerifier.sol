// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EquitoMessageLibrary} from "../libraries/EquitoMessageLibrary.sol";

interface IEquitoVerifier {
    error MessageAlreadyVerified(bytes32 messageHash);

    event MessageVerified(
        EquitoMessageLibrary.EquitoMessage message,
        address validator
    );

    function verifyMessages(
        EquitoMessageLibrary.EquitoMessage calldata messages,
        bytes calldata signature
    ) external;
}
