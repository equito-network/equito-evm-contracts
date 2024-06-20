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
        verifier.setRouter(address(router));
        
        vm.stopPrank();
        
        // Set cost message usd
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(bytes1(0x02), messageCostUsd);

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectEmit(true, true, true, true);
        emit MessageCostUsdSet(messageCostUsd);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);
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

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(bytes1(0x07));

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectRevert(Errors.InvalidOperation.selector);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);
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

    /// @dev Tests the onlySovereign modifier with an invalid chain ID
    function testOnlySovereignModifierWithInvalidChainId() public {
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
        uint256 expectedFee = (messageCostUsd * 1e18) / oracleTokenPriceUsd;
        uint256 fee = verifier.getFee(ALICE);

        assertEq(fee, expectedFee, "Incorrect fee calculated");
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

    /// @notice Tests the receive message with set message cost usd command.
    function testReceiveMessageSetMessageCostUsd() external {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(bytes1(0x02), 0.5 ether);

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectEmit(true, true, true, true);
        emit MessageCostUsdSet(0.5 ether);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);

        assertEq(
            verifier.messageCostUsd(),
            0.5 ether,
            "Message cost USD not set correctly"
        );
    }

    /// @notice Tests the receive message with set message cost usd command when cost muct be greater than zero.
    function testReceiveMessageSetMessageCostUsdCostMustBeGreaterThanZero() external {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(bytes1(0x02), 0);

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectRevert(Errors.CostMustBeGreaterThanZero.selector);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);
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

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(
            bytes1(0x03),
            liquidityProvider,
            session,
            transferAmount
        );

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));
        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.prank(address(verifier));
        vm.expectEmit(true, true, true, true);
        emit FeesTransferred(liquidityProvider, session, transferAmount);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);

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

    /// @notice Tests the receive message with transfer fees when an invalid liquidity provider.
    function testReceiveMessageTransferFeesInvalidLiquidityProvider() external {
        uint256 initialAmount = 1 ether;
        uint256 transferAmount = 0.5 ether;
        address liquidityProvider = address(0);
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

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(
            bytes1(0x03),
            liquidityProvider,
            session,
            transferAmount
        );

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));
        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.prank(address(verifier));
        vm.expectRevert(Errors.InvalidLiquidityProvider.selector);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);
    }

    /// @notice Tests the receive message with transfer fees when no fees available.
    function testReceiveMessageTransferFeesNoFeesAvailable() external {
        uint256 transferAmount = 0.5 ether;
        address liquidityProvider = BOB;
        uint256 session = verifier.session();


        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(
            bytes1(0x03),
            liquidityProvider,
            session,
            transferAmount
        );

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));
        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.prank(address(verifier));
        vm.expectRevert(Errors.NoFeesAvailable.selector);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);
    }

    /// @notice Tests the receive message with transfer fees when the amount exceeds available fees.
    function testReceiveMessageTransferFeesAmountExceedsFees() external {
        uint256 initialAmount = 1 ether;
        uint256 transferAmount = 1.5 ether;
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

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(
            bytes1(0x03),
            liquidityProvider,
            session,
            transferAmount
        );

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));
        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.prank(address(verifier));
        vm.expectEmit(true, true, true, true);
        emit FeesTransferred(liquidityProvider, session, initialAmount);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);

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

    
    /// @notice Tests the receive message with transfer fees when the transfer fails.
    function testReceiveMessageTransferFeesTransferFailed() external {
        uint256 initialAmount = 1 ether;
        uint256 transferAmount = 0.5 ether;
        address payable invalidLiquidityProvider = payable(
            address(new MockInvalidReceiver())
        );
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

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(
            bytes1(0x03),
            invalidLiquidityProvider,
            0,
            transferAmount
        );

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));
        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.prank(address(verifier));
        vm.expectRevert(Errors.TransferFailed.selector);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);
    }

    /// @notice Tests the receive message with update validators command.
    function testReceiveMessageUpdateValidators() external {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (address charleth, uint256 charlethSecret) = makeAddrAndKey("charleth");

        uint256 session = verifier.session();

        address[] memory validators = new address[](1);
        validators[0] = charleth;

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(bytes1(0x01), session, validators);

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectEmit(true, true, true, true);
        emit ValidatorSetUpdated();
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);

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

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(bytes1(0x01), session + 1, validators);

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectRevert(Errors.SessionIdMismatch.selector);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);
    }

    /// @notice Test receiving a message to add an address to the noFee list
    function testReceiveMessageAddNoFeeAddress() external {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        bytes[] memory messageData = new bytes[](1);
        messageData[0] = abi.encode(bytes1(0x04), BOB);

        EquitoMessage[] memory messages = new EquitoMessage[](1);
        messages[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData[0])
        });

        bytes32 messageHash = keccak256(abi.encode(messages[0]));

        bytes memory proof = bytes.concat(
            signMessage(messageHash, charlethSecret),
            signMessage(messageHash, alithSecret),
            signMessage(messageHash, baltatharSecret)
        );

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressAdded(BOB);
        router.deliverAndExecuteMessages(messages, messageData, 0, proof);

        assertEq(verifier.noFee(BOB), true, "No fee address not set correctly");
    }

    /// @notice Test receiving a message to remove an address from the noFee list
    function testReceiveMessageRemoveNoFeeAddress() external {
        (, uint256 alithSecret) = makeAddrAndKey("alith");
        (, uint256 baltatharSecret) = makeAddrAndKey("baltathar");
        (, uint256 charlethSecret) = makeAddrAndKey("charleth");

        // Add no fee address
        bytes[] memory messageData1 = new bytes[](1);
        messageData1[0] = abi.encode(bytes1(0x04), BOB);

        EquitoMessage[] memory messages1 = new EquitoMessage[](1);
        messages1[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData1[0])
        });

        bytes32 messageHash1 = keccak256(abi.encode(messages1[0]));

        bytes memory proof1 = bytes.concat(
            signMessage(messageHash1, charlethSecret),
            signMessage(messageHash1, alithSecret),
            signMessage(messageHash1, baltatharSecret)
        );

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressAdded(BOB);
        router.deliverAndExecuteMessages(messages1, messageData1, 0, proof1);

        // Remove no fee address
        bytes[] memory messageData2 = new bytes[](1);
        messageData2[0] = abi.encode(bytes1(0x05), BOB);

        EquitoMessage[] memory messages2 = new EquitoMessage[](1);
        messages2[0] = EquitoMessage({
            blockNumber: 0,
            sourceChainSelector: 0,
            sender: EquitoMessageLibrary.addressToBytes64(equitoAddress),
            destinationChainSelector: 1,
            receiver: EquitoMessageLibrary.addressToBytes64(address(verifier)),
            hashedData: keccak256(messageData2[0])
        });

        bytes32 messageHash2 = keccak256(abi.encode(messages2[0]));

        bytes memory proof2 = bytes.concat(
            signMessage(messageHash2, charlethSecret),
            signMessage(messageHash2, alithSecret),
            signMessage(messageHash2, baltatharSecret)
        );

        vm.expectEmit(true, true, true, true);
        emit NoFeeAddressRemoved(BOB);
        router.deliverAndExecuteMessages(messages2, messageData2, 0, proof2);

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