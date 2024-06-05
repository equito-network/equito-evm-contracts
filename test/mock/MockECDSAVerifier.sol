// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {ECDSAVerifier} from "../../src/ECDSAVerifier.sol";
import {EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {IEquitoVerifier} from "../../src/interfaces/IEquitoVerifier.sol";
import {IOracle} from "../../src/interfaces/IOracle.sol";
import {Errors} from "../../src/libraries/Errors.sol";

contract MockECDSAVerifier is ECDSAVerifier {
    constructor(address[] memory _validators, uint256 _session, address _oracle, address _router) ECDSAVerifier(_validators, _session, _oracle, _router) {}

    function transferFees(address liquidityProvider, uint256 amount) external { 
        _transferFees(liquidityProvider, amount);
    }

    function setMessageCostUsd(uint256 _messageCostUsd) external {
        _setMessageCostUsd(_messageCostUsd);
    }
}