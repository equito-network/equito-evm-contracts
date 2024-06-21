// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "../../src/Router.sol";
import {IEquitoFees} from "../../src/interfaces/IEquitoFees.sol";
import {bytes64, EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {IEquitoVerifier} from "../../src/interfaces/IEquitoVerifier.sol";
import {Test, console} from "forge-std/Test.sol";

contract MockRouter is IRouter {
    uint256 public immutable chainSelector;
    bytes64 public equitoAddress;

    constructor(uint256 _chainSelector, bytes64 memory _equitoAddress) {
        chainSelector = _chainSelector;
        equitoAddress = _equitoAddress;
    }

    function sendMessage(
        bytes64 calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external payable override returns (bytes32) {
        return keccak256(abi.encode(receiver, destinationChainSelector, data));
    }

    function deliverAndExecuteMessage(
        EquitoMessage calldata message,
        bytes calldata messageData,
        uint256 verifierIndex,
        bytes calldata proof
    ) external payable {}

    function deliverMessages(
        EquitoMessage[] calldata messages,
        uint256 verifierIndex,
        bytes calldata proof
    ) external {}

    function executeMessage(
        EquitoMessage calldata messages,
        bytes calldata messageData
    ) external payable {}

    function _setEquitoAddress(bytes64 memory _equitoAddress) internal {
        equitoAddress = _equitoAddress;
    }
}
