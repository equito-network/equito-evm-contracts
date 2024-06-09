// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {IRouter} from "../../src/Router.sol";
import {IEquitoFees} from "../../src/interfaces/IEquitoFees.sol";
import {IEquitoReceiver} from "../../src/interfaces/IEquitoReceiver.sol";
import {bytes64, EquitoMessage} from "../../src/libraries/EquitoMessageLibrary.sol";
import {IEquitoVerifier} from "../../src/interfaces/IEquitoVerifier.sol";
import {Test, console} from "forge-std/Test.sol";

contract MockRouter is IRouter, IEquitoReceiver {
    uint256 public immutable chainSelector;

    address public equitoAddress;

    IEquitoVerifier[] public verifiers;

    mapping(bytes32 => bool) public isDuplicateMessage;

    IEquitoFees public equitoFees;

    constructor(uint256 _chainSelector, address _initialVerifier, address _equitoFees, address _equitoAddress) {
        chainSelector = _chainSelector;
        verifiers.push(IEquitoVerifier(_initialVerifier));

        equitoFees = IEquitoFees(_equitoFees);

        equitoAddress = _equitoAddress;
    }

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

    function receiveMessage(
        EquitoMessage calldata message,
        bytes calldata messageData
    ) external override {}

    function _addVerifier(
        address _newVerifier,
        uint256 verifierIndex,
        bytes calldata proof
    ) internal {}

    function _setEquitoFees(
        address _equitoFees
    ) internal {}

    function _setEquitoAddress(bytes64 memory _equitoAddress) internal {}
}
