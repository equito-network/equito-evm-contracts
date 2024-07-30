// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {ECDSAVerifier} from "../src/ECDSAVerifier.sol";
import {bytes64, EquitoMessage, EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockOracle} from "./mock/MockOracle.sol";
import {Router} from "../src/Router.sol";
import {MockInvalidReceiver} from "./mock/MockInvalidReceiver.sol";
import {MockECDSAVerifier} from "./mock/MockECDSAVerifier.sol";
import {Errors} from "../src/libraries/Errors.sol";

contract ECDSAVerifierTest is Test {
    MockECDSAVerifier verifier;
    MockOracle oracle;
    Router router;

    uint256 messageCostUsd = 1_000;
    uint256 oracleTokenPriceUsd = 3500_000;

    address constant OWNER = address(0x03132);
    address constant ALICE = address(0xA11CE);
    address constant BOB = address(0xB0B);
    address constant CHARLIE = address(0xC04);
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
        oracle = new MockOracle(oracleTokenPriceUsd);
        verifier = new MockECDSAVerifier(validators, 0, address(oracle));
        router = new Router(
            1,
            address(verifier),
            address(verifier),
            EquitoMessageLibrary.addressToBytes64(equitoAddress)
        );
        verifier.setMessageCostUsd(messageCostUsd);
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
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        bytes memory messageData = abi.encode(bytes1(0x07));

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData)
        });

        bytes32 messageHash = keccak256(abi.encode(message));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectRevert(Errors.InvalidOperation.selector);
        router.deliverAndExecuteMessage(message, messageData, 0, proof);
    }

    /// @dev Tests the onlySovereign modifier with an invalid sender
    function testOnlySovereignModifierWithInvalidSender() public {
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(ALICE),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: keccak256(abi.encode(0x01))
        });

        vm.prank(address(router));
        vm.expectRevert(Errors.InvalidSovereign.selector);
        verifier.receiveMessage(message, abi.encode(0x01));
    }

    /// @dev Tests the onlySovereign modifier with an invalid chain selector
    function testOnlySovereignModifierWithInvalidchainSelector() public {
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: keccak256(abi.encode(0x01))
        });

        vm.prank(address(router));
        vm.expectRevert(Errors.InvalidSovereign.selector);
        verifier.receiveMessage(message, abi.encode(0x01));
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

    /// @notice Tests the verification of a single message.
    function testVerifyMessage() public {
        (address alith, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 1,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(alith),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(alith),
            hashedData: keccak256(abi.encode("Hello, World!"))
        });
        bytes32 messageHash = keccak256(abi.encode(message));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        console.log(verifier.verifyMessage(message, proof));
    }

    /// @notice Tests the verification of a single message using verifyMessages.
    function testVerifyMessagesSingleMessage() public {
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
            hashedData: keccak256(abi.encode("Hello, World!"))
        });
        bytes32 messageHash = keccak256(abi.encode(messages[0]));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        console.log(verifier.verifyMessages(messages, proof));
    }

    function testVerifyMessagesMultipleMessages() public {
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
            hashedData: keccak256(abi.encode("Message #1"))
        });
        messages[1] = EquitoMessage({
            blockNumber: 2,
            sourceChainSelector: 2,
            sender: EquitoMessageLibrary.addressToBytes64(baltathar),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(alith),
            hashedData: keccak256(abi.encode("Message #2"))
        });
        messages[2] = EquitoMessage({
            blockNumber: 3,
            sourceChainSelector: 1,
            sender: EquitoMessageLibrary.addressToBytes64(alith),
            destinationChainSelector: 3,
            receiver: EquitoMessageLibrary.addressToBytes64(charleth),
            hashedData: keccak256(abi.encode("Message #3"))
        });
        messages[3] = EquitoMessage({
            blockNumber: 4,
            sourceChainSelector: 3,
            sender: EquitoMessageLibrary.addressToBytes64(charleth),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(alith),
            hashedData: keccak256(abi.encode("Message #4"))
        });
        messages[4] = EquitoMessage({
            blockNumber: 5,
            sourceChainSelector: 3,
            sender: EquitoMessageLibrary.addressToBytes64(charleth),
            destinationChainSelector: 2,
            receiver: EquitoMessageLibrary.addressToBytes64(alith),
            hashedData: keccak256(abi.encode("Message #5"))
        });
        bytes32 messagesHash = keccak256(abi.encode(messages));

        bytes memory proof = bytes.concat(
            signMessage(messagesHash, charlethSecret),
            signMessage(messagesHash, alithSecret),
            signMessage(messagesHash, baltatharSecret)
        );

        console.log(verifier.verifyMessages(messages, proof));
    }

    /// @notice Tests the verification of empty messages, which should fail.
    function testVerifyEmptyMessagesFails() public view {
        EquitoMessage[] memory messages = new EquitoMessage[](0);
        bytes memory proof = "";

        assert(!verifier.verifyMessages(messages, proof));
    }

    /// @notice Tests getting the fee.
    function testGetFee() external {
        uint256 expectedFee = (messageCostUsd * 1e18) / oracleTokenPriceUsd;
        uint256 fee = verifier.getFee(ALICE);

        assertEq(fee, expectedFee, "Incorrect fee calculated");
    }

    /// @notice Tests getting the fee for no fee address.
    function testGetFeeForNoFeeAddress() external {
        uint256 expectedFee = (messageCostUsd * 1e18) / oracleTokenPriceUsd;
        uint256 fee = verifier.getFee(ALICE);
        assertEq(fee, expectedFee, "Incorrect fee calculated");

        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressAdded(ALICE);
        verifier.addNoFeeAddress(ALICE);

        assertEq(verifier.getFee(ALICE), 0, "Incorrect fee calculated");

        assertEq(
            verifier.getFee(address(verifier)),
            0,
            "Incorrect fee calculated"
        );
    }

    /// @notice Test paying the fee with sufficient amount.
    function testPayFeeSuccess() public {
        vm.deal(ALICE, 1 ether);
        vm.prank(ALICE);

        uint256 fee = verifier.getFee(ALICE);

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
        vm.deal(CHARLIE, 1 ether);
        vm.prank(CHARLIE);

        uint256 fee = verifier.getFee(ALICE);
        uint256 insufficientFee = 1;

        vm.expectRevert(Errors.InsufficientFee.selector);
        verifier.payFee{value: insufficientFee}(CHARLIE);
    }

    /// @notice Test adding an address to the noFee list
    function testAddNoFeeAddress() public {
        vm.prank(OWNER);

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressAdded(ALICE);
        verifier.addNoFeeAddress(ALICE);

        assertEq(
            verifier.noFee(ALICE),
            true,
            "No fee address not set correctly"
        );
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
        verifier.transferFees(liquidityProvider, session, transferAmount);

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

    /// @notice Tests the transfer fees with previous session ID.
    function testTransferFeesWithPreviousSessionId() public {
        // Pay fee for session 0
        uint256 initialAmount = 0.1 ether;
        verifier.payFee{value: initialAmount}(ALICE);

        // Updated session to 1
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (address charleth, uint256 charlethSecret) = makeAddrAndKey("charleth");

        uint256 session = verifier.session();

        address[] memory validators = new address[](1);
        validators[0] = charleth;

        bytes memory messageData  = abi.encode(bytes1(0x01), session, validators);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData)
        });

        bytes32 messageHash = keccak256(abi.encode(message));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        router.deliverAndExecuteMessage(message, messageData, 0, proof);

        // Transfer fees for session 0
        uint256 prevSession = verifier.session() - 1;
        uint256 transferAmount = 0.1 ether;
        address liquidityProvider = BOB;

        assertEq(
            liquidityProvider.balance,
            0,
            "Initial liquidity provider balance should be 0"
        );

        vm.expectEmit(true, true, true, true);
        emit FeesTransferred(liquidityProvider, prevSession, transferAmount);

        vm.prank(address(this));
        verifier.transferFees(liquidityProvider, prevSession, transferAmount);

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
        uint256 session = verifier.session();

        vm.expectRevert(Errors.InvalidLiquidityProvider.selector);
        verifier.transferFees(address(0), session, transferAmount);
    }

    /// @notice Tests the transfer fees with an invalid session ID.
    function testTransferFeesInvalidSessionId() public {
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
        uint256 invalidSessionId = verifier.session() + 1;
        address liquidityProvider = BOB;

        assertEq(
            liquidityProvider.balance,
            0,
            "Initial liquidity provider balance should be 0"
        );

        vm.expectRevert(Errors.InvalidSessionId.selector);
        verifier.transferFees(liquidityProvider, invalidSessionId, transferAmount);
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
        verifier.transferFees(liquidityProvider, session, transferAmount);

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
        uint256 session = verifier.session();
        address payable invalidLiquidityProvider = payable(
            address(new MockInvalidReceiver())
        );

        vm.expectRevert(Errors.TransferFailed.selector);
        verifier.transferFees(invalidLiquidityProvider, session, transferAmount);
    }

    /// @notice Tests the receive message with update validators command.
    function testReceiveMessageUpdateValidators() external {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (address charleth, uint256 charlethSecret) = makeAddrAndKey("charleth");

        uint256 session = verifier.session();

        address[] memory validators = new address[](1);
        validators[0] = charleth;

        bytes memory messageData = abi.encode(
            bytes1(0x01),
            session,
            validators
        );

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData)
        });

        bytes32 messageHash = keccak256(abi.encode(message));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectEmit(true, true, true, true);
        emit ValidatorSetUpdated();
        router.deliverAndExecuteMessage(message, messageData, 0, proof);

        assert(verifier.validators(0) == charleth);
        assertEq(verifier.session(), session + 1);
    }

    /// @notice Tests the receive message with update validators command when session IDs do not match.
    function testReceiveMessageUpdateValidatorsSessionIdMismatch() external {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        uint256 session = verifier.session();

        address[] memory validators = new address[](1);

        bytes memory messageData = abi.encode(
            bytes1(0x01),
            session + 1,
            validators
        );

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData)
        });

        bytes32 messageHash = keccak256(abi.encode(message));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectRevert(Errors.SessionIdMismatch.selector);
        router.deliverAndExecuteMessage(message, messageData, 0, proof);
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

        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        bytes memory messageData = abi.encode(bytes1(0x02), 0.5 ether);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData)
        });

        bytes32 messageHash = keccak256(abi.encode(message));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectEmit(true, true, true, true);
        emit MessageCostUsdSet(0.5 ether);
        router.deliverAndExecuteMessage(message, messageData, 0, proof);

        assertEq(
            verifier.messageCostUsd(),
            0.5 ether,
            "Message cost USD not set correctly"
        );
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

        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        bytes memory messageData = abi.encode(
            bytes1(0x03),
            liquidityProvider,
            session,
            transferAmount
        );

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData)
        });

        bytes32 messageHash = keccak256(abi.encode(message));
        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.prank(address(verifier));
        vm.expectEmit(true, true, true, true);
        emit FeesTransferred(liquidityProvider, session, transferAmount);
        router.deliverAndExecuteMessage(message, messageData, 0, proof);

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

    /// @notice Test receiving a message to add an address to the noFee list
    function testReceiveMessageAddNoFeeAddress() external {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        bytes memory messageData = abi.encode(bytes1(0x04), BOB);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData)
        });

        bytes32 messageHash = keccak256(abi.encode(message));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressAdded(BOB);
        router.deliverAndExecuteMessage(message, messageData, 0, proof);

        assertEq(verifier.noFee(BOB), true, "No fee address not set correctly");
    }

    /// @notice Test receiving a message to remove an address from the noFee list
    function testReceiveMessageRemoveNoFeeAddress() external {
        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressAdded(BOB);
        verifier.addNoFeeAddress(BOB);
        assertEq(verifier.noFee(BOB), true, "No fee address not set correctly");

        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        bytes memory messageData = abi.encode(bytes1(0x05), BOB);

        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData)
        });

        bytes32 messageHash = keccak256(abi.encode(message));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressRemoved(BOB);
        router.deliverAndExecuteMessage(message, messageData, 0, proof);

        assertEq(verifier.noFee(BOB), false, "No fee address not removed");
    }

    /// @notice Tests the receive message with invalid command.
    function testReceiveMessageInvalidOperation() external {
        EquitoMessage memory message = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 0,
            receiver: EquitoMessageLibrary.addressToBytes64(BOB),
            hashedData: keccak256(abi.encode(bytes1(0x07)))
        });

        vm.prank(address(router));
        vm.expectRevert(Errors.InvalidOperation.selector);
        verifier.receiveMessage(message, abi.encode(bytes1(0x07)));
    }
}
