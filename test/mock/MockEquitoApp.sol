// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "../../src/Router.sol";
import {EquitoApp} from "../../src/EquitoApp.sol";
import {EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {IEquitoVerifier} from "../../src/interfaces/IEquitoVerifier.sol";

contract MockEquitoApp is EquitoApp {
    constructor(address _router) EquitoApp(_router) {}
}