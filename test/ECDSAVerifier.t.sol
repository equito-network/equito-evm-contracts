// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {ECDSAVerifier} from "../src/ECDSAVerifier.sol";
import {EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockOracle} from "./mock/MockOracle.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract ECDSAVerifierTest is Test {
    ECDSAVerifier verifier;
    MockOracle oracle;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);

    event FeePaid(address indexed payer, uint256 amount);
    event CostMessageUsdSet(uint256 newCostMessageUsd);
    event LiquidityProviderSet(address indexed newLiquidityProvider);

    function setUp() public {
        (address alith, ) = makeAddrAndKey("alith");
        (address baltathar, ) = makeAddrAndKey("baltathar");
        (address charleth, ) = makeAddrAndKey("charleth");

        address[] memory validators = new address[](3);
        validators[0] = alith;
        validators[1] = baltathar;
        validators[2] = charleth;

        vm.startPrank(OWNER);
        oracle = new MockOracle();
        verifier = new ECDSAVerifier(validators, 0, address(oracle));
        verifier.setCostMessageUsd(1000);
        vm.stopPrank();
    }

    function signMessage(
        bytes32 messageHash,
        uint256 secret
    ) private pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(secret, messageHash);
        return abi.encodePacked(r, s, v);
    }

    /// @notice Tests the verification of messages.
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

    /// @notice Tests the updating of validators.
    function testUpdateValidators() public {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (address charleth, uint256 charlethSecret) = makeAddrAndKey("charleth");

        uint256 session = verifier.session();

        address[] memory validators = new address[](1);
        validators[0] = charleth;
        bytes32 messageHash = keccak256(abi.encode(session, validators));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        verifier.updateValidators(validators, proof);

        assert(verifier.validators(0) == charleth);
        assertEq(verifier.session(), session + 1);

        vm.expectRevert();
        console.log(verifier.validators(1));

        console.log("Validators updated successfully!");

        messageHash = keccak256(abi.encode("Hello, World!"));
        proof = signMessage(messageHash, charlethSecret);
        assert(verifier.verifySignatures(messageHash, proof));
    }

    /// @notice Tests the verification of empty messages, which should fail.
    function testVerifyEmptyMessagesFails() public view {
        EquitoMessage[] memory messages = new EquitoMessage[](0);
        bytes memory proof = "";

        assert(!verifier.verifyMessages(messages, proof));
    }

    /// @notice Tests the verification of signatures with an invalid proof length, which should fail.
    function testVerifySignaturesWithInvalidProofLengthFails() public view {
        bytes32 messageHash = keccak256(abi.encode("Hello, World!"));
        bytes memory proof = "0x";

        assert(!verifier.verifySignatures(messageHash, proof));
    }

    /// @notice Tests the verification of duplicate signatures, which should fail.
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

    /// @notice Tests getting the fee.
    function testGetFee() external {
        uint256 expectedFee = 1000 / 100;
        uint256 fee = verifier.getFee();

        assertEq(fee, expectedFee, "Incorrect fee calculated");
    }

    /// @notice Test paying the fee with sufficient amount.
    function testPayFeeSuccess() public {
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE);

        uint256 fee = verifier.getFee();

        vm.expectEmit(true, true, true, true);
        emit FeePaid(ALICE, fee);
        verifier.payFee{value: fee}(ALICE);
    }

    /// @notice Test paying the fee with insufficient amount.
    function testPayFeeInsufficient() public {
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE);

        uint256 fee = verifier.getFee();
        uint256 insufficientFee = 1;
        uint256 costMessageUsd = verifier.costMessageUsd();

        vm.expectRevert(Errors.InsufficientFee.selector);
        verifier.payFee{value: insufficientFee}(ALICE);
    }

    /// @notice Tests setting the cost of a message in USD.
    function testSetCostMessageUsd() public {
        vm.prank(OWNER);

        vm.expectEmit(true, true, true, true);
        emit CostMessageUsdSet(100);
        verifier.setCostMessageUsd(100);

        assertEq(verifier.costMessageUsd(), 100, "Cost message USD not set correctly");
    }

    /// @notice Tests setting the cost of a message in USD with a value of zero.
    function testSetCostMessageUsdCostMustBeGreaterThanZero() public {
        vm.prank(OWNER);
        
        vm.expectRevert(Errors.CostMustBeGreaterThanZero.selector);
        verifier.setCostMessageUsd(0);
    }

    /// @notice Tests setting the liquidity provider address.
    function testSetLiquidityProvider() public {
        vm.prank(OWNER);

        vm.expectEmit(true, true, true, true);
        emit LiquidityProviderSet(BOB);
        verifier.setLiquidityProvider(BOB);

        assertEq(verifier.liquidityProvider(), BOB, "Liquidity provider not set correctly");
    }

    /// @notice Tests setting an invalid liquidity provider address.
    function testSetLiquidityProviderInvalidAddress() public {
        vm.prank(OWNER);

        vm.expectRevert(Errors.InvalidAddress.selector);
        verifier.setLiquidityProvider(address(0));
    }
}
