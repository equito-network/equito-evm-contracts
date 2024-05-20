// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {EquitoMessage} from "../libraries/EquitoMessageLibrary.sol";

interface IEquitoReceiver {
    /// @notice Receives a cross-chain message from the Router Contract.
    /// @param message The Equito message received.
    function receiveMessage(EquitoMessage calldata message) external;
}
