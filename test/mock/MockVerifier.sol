// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {IEquitoVerifier} from "../../src/interfaces/IEquitoVerifier.sol";

/// Mock Verifier that returns true for all non-empty proofs.
contract MockVerifier is IEquitoVerifier {
    function verifyMessage(
        EquitoMessage[] calldata messages,
        bytes calldata proof
    ) external override returns (bool) {
        return proof.length > 0;
    }

    function verifyMessages(
        EquitoMessage[] calldata messages,
        bytes calldata proof
    ) external override returns (bool) {
        return proof.length > 0;
    }
}