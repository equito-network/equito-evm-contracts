// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IEquitoVerifier} from "./interfaces/IEquitoVerifier.sol";
import {EquitoMessageLibrary} from "./libraries/EquitoMessageLibrary.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ECDSAVerifier is IEquitoVerifier {
    address[] public validatorAddress;
    uint256 public immutable threshold = 70;

    mapping(bytes32 => uint256) public messageToSignaturesCount;

    constructor(address[] memory _validatorAddress) {
        validatorAddress = _validatorAddress;
    }

    function verifyMessages(
        EquitoMessageLibrary.EquitoMessage calldata messages,
        bytes calldata signature
    ) external override {
        bytes32 messageHash = EquitoMessageLibrary._hash(messages);

        if (
            (messageToSignaturesCount[messageHash] * 100) /
                validatorAddress.length >=
            threshold
        ) revert MessageAlreadyVerified(messageHash);

        for (uint256 i = 0; i < validatorAddress.length; i++) {
            if (ECDSA.recover(messageHash, signature) == validatorAddress[i]) {
                messageToSignaturesCount[messageHash]++;
            }
        }
    }
}
