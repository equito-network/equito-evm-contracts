// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "../../src/Router.sol";
import {EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {IEquitoVerifier} from "../../src/interfaces/IEquitoVerifier.sol";

contract MockRouter is IRouter {
    uint256 public immutable chainSelector;

    IEquitoVerifier[] public verifiers;

    mapping(bytes32 => bool) public isDuplicateMessage;

    function sendMessage(
        bytes calldata receiver,
        uint256 destinationChainSelector,
        bytes calldata data
    ) external override returns (bytes32) {
        return keccak256(
                abi.encode(
                    receiver,
                    destinationChainSelector,
                    data
                )
            );
    }
    
    function routeMessages(
        EquitoMessage[] calldata messages,
        uint256 verifierIndex,
        bytes calldata proof
    ) external {}

    function deliverMessages(
        EquitoMessage[] calldata messages,
        uint256 verifierIndex,
        bytes calldata proof
    ) external {}

    function executeMessages(
        EquitoMessage[] calldata messages
    ) external {}

    function addVerifier(
        address _newVerifier,
        uint256 verifierIndex,
        bytes calldata proof
    ) external {}
}