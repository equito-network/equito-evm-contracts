// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "../../src/Router.sol";
import {IEquitoFees} from "../../src/interfaces/IEquitoFees.sol";
import {bytes64, EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {IEquitoVerifier} from "../../src/interfaces/IEquitoVerifier.sol";

contract MockRouter is IRouter {
    uint256 public immutable chainSelector;

    IEquitoVerifier[] public verifiers;

    mapping(bytes32 => bool) public isDuplicateMessage;

    IEquitoFees public equitoFees;

    function sendMessage(
        bytes64 calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external payable override returns (bytes32) {
        return keccak256(abi.encode(receiver, destinationChainSelector, data));
    }

    function deliverAndExecuteMessages(
        EquitoMessage[] calldata messages,
        bytes[] calldata messageData,
        uint256 verifierIndex,
        bytes calldata proof
    ) external {}

    function deliverMessages(
        EquitoMessage[] calldata messages,
        uint256 verifierIndex,
        bytes calldata proof
    ) external {}

    function executeMessages(
        EquitoMessage[] calldata messages,
        bytes[] calldata messageData
    ) external {}

    function addVerifier(
        address _newVerifier,
        uint256 verifierIndex,
        bytes calldata proof
    ) external {}
}
