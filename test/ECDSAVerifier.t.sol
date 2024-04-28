// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {ECDSAVerifier} from "../src/ECDSAVerifier.sol";
import {EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";

contract ECDSAVerifierTest is Test {
    ECDSAVerifier verifier;

    function setUp() public {
        (address alith, ) = makeAddrAndKey("alith");
        (address baltathar, ) = makeAddrAndKey("baltathar");
        (address charleth, ) = makeAddrAndKey("charleth");

        address[] memory validators = new address[](3);
        validators[0] = alith;
        validators[1] = baltathar;
        validators[2] = charleth;

        verifier = new ECDSAVerifier(validators);
    }

    function signMessage(
        bytes32 messageHash,
        uint256 secret
    ) private pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(secret, messageHash);
        return abi.encodePacked(r, s, v);
    }

    function testVerifyMessages() public {
        (address alith, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: abi.encode(alith),
            destinationChainSelector: 2,
            receiver: abi.encode(alith),
            data: abi.encode("Hello, World!")
        });
        bytes32 messageHash = EquitoMessageLibrary._hash(messages[0]);

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        console.log(verifier.verifyMessages(messages, proof));
    }

    function testUpdateValidators() public {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (address charleth, uint256 charlethSecret) = makeAddrAndKey("charleth");

        address[] memory validators = new address[](1);
        validators[0] = charleth;
        bytes32 messageHash = keccak256(abi.encode(validators));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        verifier.updateValidators(validators, proof);

        assert(verifier.validators(0) == charleth);
        vm.expectRevert();
        console.log(verifier.validators(1));

        console.log("Validators updated successfully!");

        messageHash = keccak256(abi.encode("Hello, World!"));
        proof = signMessage(messageHash, charlethSecret);
        assert(verifier.verifySignatures(messageHash, proof));
    }

    function testVerifyEmptyMessagesFails() public {
        EquitoMessage[] memory messages = new EquitoMessage[](0);
        bytes memory proof = "";

        assert(!verifier.verifyMessages(messages, proof));
    }

    function testVerifySignaturesWithInvalidProofLengthFails() public view {
        bytes32 messageHash = keccak256(abi.encode("Hello, World!"));
        bytes memory proof = "0x";

        assert(!verifier.verifySignatures(messageHash, proof));
    }

    function testVerifyDuplicateSignaturesFails() public {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        bytes32 messageHash = keccak256(abi.encode("Hello, World!"));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, alithSecret)
        );

        assert(!verifier.verifySignatures(messageHash, proof));
    }
}
