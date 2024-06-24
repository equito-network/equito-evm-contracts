// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {IEquitoVerifier} from "../../src/interfaces/IEquitoVerifier.sol";

/// Mock Verifier that returns true for all non-empty proofs.
contract MockVerifier is IEquitoVerifier {
    address public router;

    function verifyMessage(
        EquitoMessage calldata message,
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

    function setRouter(address _router) external override {
        require(_router != address(0), "Router address cannot be zero");
        router = _router;
    }
}
