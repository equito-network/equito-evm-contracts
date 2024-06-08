// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {ECDSAVerifier} from "../src/ECDSAVerifier.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockOracle} from "./mock/MockOracle.sol";
import {MockRouter} from "./mock/MockRouter.sol";
import {MockInvalidReceiver} from "./mock/MockInvalidReceiver.sol";
import {MockECDSAVerifier} from "./mock/MockECDSAVerifier.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract ECDSAVerifierTest is Test {
    MockECDSAVerifier verifier;
    MockOracle oracle;
    MockRouter router;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address equitoAddress = address(0x45717569746f);

    event FeePaid(address indexed payer, uint256 amount);
    event MessageCostUsdSet(uint256 newMessageCostUsd);
    event LiquidityProviderSet(address indexed newLiquidityProvider);
    event FeesTransferred(
        address indexed liquidityProvider,
        uint256 session,
        uint256 amount
    );
    event ValidatorSetUpdated();
    event EquitoAddressSet();
    event NoFeeAddressAdded(address indexed noFeeAddress);
    event NoFeeAddressRemoved(address indexed noFeeAddress);

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
        router = new MockRouter();
        verifier = new MockECDSAVerifier(
            validators,
            0,
            address(oracle),
            EquitoMessageLibrary.addressToBytes64(equitoAddress)
        );
        verifier.setRouter(address(router));
        verifier.setMessageCostUsd(1000);
        vm.stopPrank();
    }

    /// @dev Tests setting a router
    function testSetRouter() public {
        vm.prank(OWNER);

        vm.expectRevert(Errors.RouterAlreadySet.selector);
        verifier.setRouter(ALICE);
    }

    /// @dev Tests the onlySovereign modifier with a valid message
    function testOnlySovereignModifierSuccess() public {
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode(0x05)
        });

        vm.prank(address(router));
        vm.expectRevert(Errors.InvalidOperation.selector);
        verifier.receiveMessage(message);
    }

    /// @dev Tests the onlySovereign modifier with an invalid sender
    function testOnlySovereignModifierWithInvalidSender() public {
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode(0x01)
        });

        vm.prank(address(router));
        vm.expectRevert(Errors.InvalidSovereign.selector);
        verifier.receiveMessage(message);
    }

    /// @dev Tests the onlySovereign modifier with an invalid chain ID
    function testOnlySovereignModifierWithInvalidChainId() public {
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode(0x01)
        });

        vm.prank(address(router));
        vm.expectRevert(Errors.InvalidSovereign.selector);
        verifier.receiveMessage(message);
    }

    /// @dev Helper function to sign a message hash with a given secret key
    /// @param messageHash The hash of the message to sign
    /// @param secret The secret key used to sign the message
    /// @return The signature of the message
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
            sender: EquitoMessageLibrary.addressToBytes64(alith),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(alith),
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

    function testVerifyMultipleMessages() public {
        (address alith, uint256 alithSecret) = makeAddrAndKey("alith");
        (address baltathar, uint256 baltatharSecret) = makeAddrAndKey(
            "baltathar"
        );
        (address charleth, uint256 charlethSecret) = makeAddrAndKey("charleth");

        EquitoMessage[] memory messages = new EquitoMessage[](5);
        messages[0] = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(alith),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(baltathar),
            data: abi.encode("Message #1")
        });
        messages[1] = EquitoMessage({
            blockNumber: 2,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(baltathar),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(alith),
            data: abi.encode("Message #2")
        });
        messages[2] = EquitoMessage({
            blockNumber: 3,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(alith),
            destinationChainSelector: 3,
            receiver: EquitoMessageLibrary.addressToBytes64(charleth),
            data: abi.encode("Message #3")
        });
        messages[3] = EquitoMessage({
            blockNumber: 4,
            sourceChainSelector: 3,
            sender: EquitoMessageLibrary.addressToBytes64(charleth),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(alith),
            data: abi.encode("Message #5")
        });
        messages[4] = EquitoMessage({
            blockNumber: 5,
            sourceChainSelector: 3,
            sender: EquitoMessageLibrary.addressToBytes64(charleth),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(alith),
            data: abi.encode("Message #5")
        });
        bytes32 messagesHash = keccak256(abi.encode(messages));

        bytes memory proof = bytes.concat(
            signMessage(messagesHash, charlethSecret),
            signMessage(messagesHash, alithSecret),
            signMessage(messagesHash, baltatharSecret)
        );

        console.log(verifier.verifyMessages(messages, proof));
    }

    /// @notice Tests the updating of validators.
    function testUpdateValidators() public {
        (address charleth, ) = makeAddrAndKey("charleth");

        uint256 session = verifier.session();

        address[] memory validators = new address[](1);
        validators[0] = charleth;

        verifier.updateValidators(validators);

        assert(verifier.validators(0) == charleth);
        assertEq(verifier.session(), session + 1);

        vm.expectRevert();
        console.log(verifier.validators(1));

        console.log("Validators updated successfully!");
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

    /// @notice Tests getting the fee for no fee address.
    function testGetFeeForNoFeeAddress() external {
        uint256 expectedFee = 1000 / 100;
        uint256 fee = verifier.getFee();
        assertEq(fee, expectedFee, "Incorrect fee calculated");

        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressAdded(ALICE);
        verifier.addNoFeeAddress(ALICE);

        vm.prank(ALICE);
        assertEq(verifier.getFee(), 0, "Incorrect fee calculated");

        vm.prank(address(verifier));
        assertEq(verifier.getFee(), 0, "Incorrect fee calculated");
    }

    /// @notice Test paying the fee with sufficient amount.
    function testPayFeeSuccess() public {
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE);

        uint256 fee = verifier.getFee();

        assertEq(
            verifier.fees(verifier.session()),
            0,
            "Incorrect fee amount for session"
        );

        vm.expectEmit(true, true, true, true);
        emit FeePaid(ALICE, fee);
        verifier.payFee{value: fee}(ALICE);

        assertEq(
            verifier.fees(verifier.session()),
            fee,
            "Incorrect fee amount for session"
        );
    }

    /// @notice Test paying the fee with insufficient amount.
    function testPayFeeInsufficient() public {
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE);

        uint256 fee = verifier.getFee();
        uint256 insufficientFee = 1;
        uint256 messageCostUsd = verifier.messageCostUsd();

        vm.expectRevert(Errors.InsufficientFee.selector);
        verifier.payFee{value: insufficientFee}(ALICE);
    }

    /// @notice Test adding an address to the noFee list
    function testAddNoFeeAddress() public {
        vm.prank(OWNER);

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressAdded(ALICE);
        verifier.addNoFeeAddress(ALICE);

        assertEq(verifier.noFee(ALICE), true, "No fee address not set correctly");
    }

    /// @notice Test removing an address from the noFee list
    function testRemoveNoFeeAddress() public {
        vm.prank(OWNER);

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressRemoved(ALICE);
        verifier.removeNoFeeAddress(ALICE);

        assertEq(verifier.noFee(ALICE), false, "No fee address not removed");
    }

    /// @notice Tests setting the cost of a message in USD.
    function testSetMessageCostUsd() public {
        vm.prank(OWNER);

        vm.expectEmit(true, true, true, true);
        emit MessageCostUsdSet(100);
        verifier.setMessageCostUsd(100);

        assertEq(
            verifier.messageCostUsd(),
            100,
            "Message cost USD not set correctly"
        );
    }

    /// @notice Tests setting the cost of a message in USD with a value of zero.
    function testSetMessageCostUsdCostMustBeGreaterThanZero() public {
        vm.prank(OWNER);

        vm.expectRevert(Errors.CostMustBeGreaterThanZero.selector);
        verifier.setMessageCostUsd(0);
    }

    /// @notice Tests setting the equito address.
    function testSetEquitoAddress() public {
        vm.prank(OWNER);

        bytes64 memory newEquitoAddress = EquitoMessageLibrary.addressToBytes64(
            address(0xbeef)
        );

        (bytes32 lower, bytes32 upper) = verifier.equitoAddress();

        assert(
            lower != newEquitoAddress.lower || upper != newEquitoAddress.upper
        );

        vm.expectEmit(true, true, true, true);
        emit EquitoAddressSet();
        verifier.setEquitoAddress(newEquitoAddress);

        (bytes32 newLower, bytes32 newUpper) = verifier.equitoAddress();

        assert(
            newLower == newEquitoAddress.lower &&
                newUpper == newEquitoAddress.upper
        );
    }

    /// @notice Tests the transfer fees.
    function testTransferFees() public {
        uint256 initialAmount = 1 ether;

        vm.deal(ALICE, initialAmount);
        vm.startPrank(ALICE);
        verifier.payFee{value: initialAmount}(ALICE);
        vm.stopPrank();

        assertEq(
            address(verifier).balance,
            initialAmount,
            "Verifier balance mismatch after fee payment"
        );

        uint256 session = verifier.session();
        uint256 transferAmount = 0.5 ether;
        address liquidityProvider = BOB;

        assertEq(
            liquidityProvider.balance,
            0,
            "Initial liquidity provider balance should be 0"
        );

        vm.expectEmit(true, true, true, true);
        emit FeesTransferred(liquidityProvider, session, transferAmount);

        vm.prank(address(this));
        verifier.transferFees(liquidityProvider, transferAmount);

        assertEq(
            address(verifier).balance,
            initialAmount - transferAmount,
            "Verifier balance mismatch after transfer"
        );
        assertEq(
            liquidityProvider.balance,
            transferAmount,
            "Liquidity provider balance mismatch after transfer"
        );
    }

    /// @notice Tests the transfer fees with an invalid liquidity provider.
    function testTransferFeesInvalidLiquidityProvider() public {
        uint256 initialAmount = 1 ether;

        vm.deal(ALICE, initialAmount);
        vm.startPrank(ALICE);
        verifier.payFee{value: initialAmount}(ALICE);
        vm.stopPrank();

        assertEq(
            address(verifier).balance,
            initialAmount,
            "Verifier balance mismatch after fee payment"
        );

        uint256 transferAmount = 0.5 ether;

        vm.expectRevert(Errors.InvalidLiquidityProvider.selector);
        verifier.transferFees(address(0), transferAmount);
    }

    /// @notice Tests the transfer fees when the amount exceeds available fees.
    function testTransferFeesAmountExceedsFees() public {
        uint256 initialAmount = 1 ether;

        // Set up initial state
        vm.deal(ALICE, initialAmount);
        vm.startPrank(ALICE);
        verifier.payFee{value: initialAmount}(ALICE);
        vm.stopPrank();

        assertEq(
            address(verifier).balance,
            initialAmount,
            "Verifier balance mismatch after fee payment"
        );

        uint256 session = verifier.session();
        uint256 transferAmount = 1.5 ether;
        address liquidityProvider = BOB;

        assertEq(
            liquidityProvider.balance,
            0,
            "Initial liquidity provider balance should be 0"
        );

        vm.expectEmit(true, true, true, true);
        emit FeesTransferred(liquidityProvider, session, initialAmount);

        vm.prank(address(verifier));
        verifier.transferFees(liquidityProvider, transferAmount);

        assertEq(
            address(verifier).balance,
            0,
            "Verifier balance mismatch after transfer"
        );
        assertEq(
            liquidityProvider.balance,
            initialAmount,
            "Liquidity provider balance mismatch after transfer"
        );
    }

    /// @notice Tests the transfer fees when the transfer fails.
    function testTransferFeesTransferFailed() public {
        uint256 initialAmount = 1 ether;

        vm.deal(ALICE, initialAmount);
        vm.startPrank(ALICE);
        verifier.payFee{value: initialAmount}(ALICE);
        vm.stopPrank();

        assertEq(
            address(verifier).balance,
            initialAmount,
            "Verifier balance mismatch after fee payment"
        );

        uint256 transferAmount = 0.5 ether;
        address payable invalidLiquidityProvider = payable(
            address(new MockInvalidReceiver())
        );

        vm.expectRevert(Errors.TransferFailed.selector);
        verifier.transferFees(invalidLiquidityProvider, transferAmount);
    }

    /// @notice Tests the receive message with update validators command.
    function testReceiveMessageUpdateValidators() external {
        (address charleth, ) = makeAddrAndKey("charleth");

        uint256 session = verifier.session();

        address[] memory validators = new address[](1);
        validators[0] = charleth;

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode(bytes1(0x01), 0, validators)
        });

        vm.expectEmit(true, true, true, true);
        emit ValidatorSetUpdated();

        verifier.receiveMessage(message);

        assert(verifier.validators(0) == charleth);
        assertEq(verifier.session(), session + 1);
    }

    /// @notice Tests the receive message with update validators command when session IDs do not match.
    function testReceiveMessageUpdateValidatorsSessionIdMismatch() external {
        uint256 session = verifier.session();

        address[] memory validators = new address[](1);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode(bytes1(0x01), session + 1, validators)
        });

        vm.expectRevert(Errors.SessionIdMismatch.selector);
        verifier.receiveMessage(message);
    }

    /// @notice Tests the receive message with set message cost usd command.
    function testReceiveMessageSetMessageCostUsd() external {
        vm.prank(OWNER);

        vm.expectEmit(true, true, true, true);
        emit MessageCostUsdSet(100);
        verifier.setMessageCostUsd(100);

        assertEq(
            verifier.messageCostUsd(),
            100,
            "Message cost USD not set correctly"
        );

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode(bytes1(0x02), 0.5 ether)
        });

        vm.expectEmit(true, true, true, true);
        emit MessageCostUsdSet(0.5 ether);
        verifier.receiveMessage(message);

        assertEq(
            verifier.messageCostUsd(),
            0.5 ether,
            "Message cost USD not set correctly"
        );
    }

    /// @notice Tests the receive message with set equito address command.
    function testReceiveMessageSetEquitoAddress() external {
        bytes64 memory newEquitoAddress = EquitoMessageLibrary.addressToBytes64(
            address(0xbeef)
        );

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode(bytes1(0x03), newEquitoAddress)
        });

        vm.expectEmit(true, true, true, true);
        emit EquitoAddressSet();
        verifier.receiveMessage(message);

        (bytes32 lower, bytes32 upper) = verifier.equitoAddress();

        assert(
            lower == newEquitoAddress.lower && upper == newEquitoAddress.upper
        );
    }

    /// @notice Test receiving a message to add an address to the noFee list
    function testReceiveMessageAddNoFeeAddress() external {
        vm.prank(OWNER);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode(bytes1(0x05), BOB)
        });

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressAdded(BOB);
        verifier.receiveMessage(message);
        
        assertEq(verifier.noFee(BOB), true, "No fee address not set correctly");
    }

    /// @notice Test receiving a message to remove an address from the noFee list
    function testReceiveMessageRemoveNoFeeAddress() external {
        vm.prank(OWNER);

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressAdded(BOB);
        verifier.addNoFeeAddress(BOB);
        
        assertEq(verifier.noFee(BOB), true, "No fee address not set correctly");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode(bytes1(0x06), BOB)
        });

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressRemoved(BOB);
        verifier.receiveMessage(message);
        
        assertEq(verifier.noFee(BOB), false, "No fee address not removed");
    }

    /// @notice Tests the receive message with transfer fees command.
    function testReceiveMessageTransferFees() external {
        uint256 initialAmount = 1 ether;
        uint256 transferAmount = 0.5 ether;
        address liquidityProvider = BOB;
        uint256 session = verifier.session();

        vm.deal(ALICE, initialAmount);
        vm.startPrank(ALICE);
        verifier.payFee{value: initialAmount}(ALICE);
        vm.stopPrank();

        assertEq(
            address(verifier).balance,
            initialAmount,
            "Verifier balance mismatch after fee payment"
        );

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(liquidityProvider),
            data: abi.encode(bytes1(0x04), liquidityProvider, transferAmount)
        });

        vm.prank(address(verifier));
        vm.expectEmit(true, true, true, true);
        emit FeesTransferred(liquidityProvider, session, transferAmount);
        verifier.receiveMessage(message);

        assertEq(
            address(verifier).balance,
            initialAmount - transferAmount,
            "Verifier balance mismatch after transfer"
        );
        assertEq(
            liquidityProvider.balance,
            transferAmount,
            "Liquidity provider balance mismatch after transfer"
        );
    }

    /// @notice Tests the receive message with invalid command.
    function testReceiveMessageInvalidOperation() external {
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            data: abi.encode(bytes1(0x07))
        });

        vm.prank(address(router));
        vm.expectRevert(Errors.InvalidOperation.selector);
        verifier.receiveMessage(message);
    }
}
