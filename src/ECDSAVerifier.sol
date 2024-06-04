// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IEquitoVerifier} from "./interfaces/IEquitoVerifier.sol";
import {IEquitoReceiver} from "./interfaces/IEquitoReceiver.sol";
import {IEquitoFees} from "./interfaces/IEquitoFees.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {EquitoMessage, EquitoMessageLibrary} from "./libraries/EquitoMessageLibrary.sol";
import {Errors} from "./libraries/Errors.sol";

/// @title ECDSAVerifier
/// @notice This contract is part of the Equito Protocol and verifies that a set of `EquitoMessage` instances
///         have been signed by a sufficient number of Validators, as determined by the threshold.
/// @dev Uses ECDSA for signature verification, adhering to the Ethereum standard.
contract ECDSAVerifier is IEquitoVerifier, IEquitoReceiver, IEquitoFees {
    /// @notice The list of validator addresses.
    address[] public validators;
    /// @notice The threshold percentage of validator signatures required for verification.
    uint256 public immutable threshold = 70;
    /// @notice The current session identifier for the validator set.
    uint256 public session;
    /// @notice The cost of sending a message in USD.
    /// @dev The cost, denominated in USD, required to send a message. This value can be used to calculate fees for message.
    uint256 public messageCostUsd;
    /// @notice Stores the session ID and accumulated fees amount.
    mapping(uint256 => uint256) public fees;
    /// @notice The sovereign account address of the Equito Substrate chain.
    address public sovereignAccount;
    /// @notice The chain ID of the Equito Substrate chain.
    uint256 public sovereignChainId;

    /// @notice The Oracle contract used to retrieve token prices.
    /// @dev This contract provides token price information required for fee calculation.
    IOracle public oracle;

    /// @notice Emitted when the validator set is updated.
    event ValidatorSetUpdated();

    /// @notice Event emitted when the cost of sending a message in USD is set.
    event MessageCostUsdSet(uint256 newMessageCostUsd);

    /// @notice Event emitted when fees are transferred to the liquidity provider.
    event FeesTransferred(address indexed liquidityProvider, uint256 session, uint256 amount);

    /// @notice Initializes the contract with the initial validator set and session identifier.
    /// @param _validators The initial list of validator addresses.
    /// @param _session The initial session identifier.
    /// @param _oracle The address of the Oracle contract used to retrieve token prices.
    constructor(address[] memory _validators, uint256 _session, address _oracle) {
        validators = _validators;
        session = _session;
        oracle = IOracle(_oracle);
    }

    modifier onlySovereign(EquitoMessage calldata message) {
        if (message.sourceChainSelector != sovereignChainId && msg.sender != sovereignAccount) revert Errors.InvalidSovereign(sovereignChainId, sovereignAccount);
        _;
    }

    /// @notice Verifies that a set of `EquitoMessage` instances have been signed by a sufficient number of Validators.
    /// @param messages The array of `EquitoMessage` instances to verify.
    /// @param proof The concatenated ECDSA signatures from the validators.
    /// @return True if the messages are verified successfully, otherwise false.
    function verifyMessages(
        EquitoMessage[] calldata messages,
        bytes calldata proof
    ) external view override returns (bool) {
        if (messages.length == 0) return false;

        bytes32 hashed;
        if (messages.length == 1) {
            hashed = EquitoMessageLibrary._hash(messages[0]);
        } else {
            // TODO: use a more efficient way to hash multiple messages
            hashed = keccak256(abi.encode(messages));
        }

        return this.verifySignatures(hashed, proof);
    }

    /// @notice Updates the list of Validators.
    /// @param _validators The new list of validator addresses.
    /// @param proof The concatenated ECDSA signatures from the current validators approving the new set.
    function updateValidators(
        address[] calldata _validators,
        bytes calldata proof
    ) external {
        bytes32 hashed = keccak256(abi.encode(session, _validators));
        if (this.verifySignatures(hashed, proof)) {
            validators = _validators;
            session += 1;
            emit ValidatorSetUpdated();
        }
    }

    /// @notice Verifies that a hashed message has been signed by a sufficient number of Validators.
    /// @param hash The hash of the message to verify.
    /// @param proof The concatenated ECDSA signatures from the validators.
    /// @return True if the signatures are verified successfully, otherwise false.
    function verifySignatures(
        bytes32 hash,
        bytes memory proof
    ) external view override returns (bool) {
        if (proof.length % 65 != 0) return false;

        uint256 validatorsLength = validators.length;
        address[] memory signatories = new address[](validatorsLength);

        uint256 c = 0;
        uint256 i = 0;

        bytes32 r;
        bytes32 s;
        uint8 v;
        address signer;

        while (i < proof.length) {
            // The Signature Verification is inspired by OpenZeppelin's ECDSA Verification:
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/4032b42694ff6599b17ffde65b2b64d7fc8a38f8/contracts/utils/cryptography/ECDSA.sol#L128-L142

            assembly {
                r := mload(add(proof, add(i, 32)))
                s := mload(add(proof, add(i, 64)))
                v := byte(0, mload(add(proof, add(i, 96))))
            }

            if (
                uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
            ) {
                signer = ecrecover(hash, v, r, s);
                if (contains(validators, signer)) {
                    if (!contains(signatories, signer)) {
                        signatories[c] = signer;
                        c += 1;
                    }
                }
            }

            i += 65;
        }

        return c >= (validatorsLength * threshold) / 100;
    }

    /// @notice Helper function to check if an address is present in an array.
    /// @param array The array of addresses to search.
    /// @param value The address to search for.
    /// @return True if the address is found, otherwise false.
    function contains(
        address[] memory array,
        address value
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    /// @notice Retrieves the fee amount required to send a message.
    /// @return The fee amount in wei.
    function getFee() external view returns (uint256) {
        return _getFee();
    }

    /// @notice Allows a payer to pay the fee for sending a message.
    /// @param payer The address of the payer who is paying the fee.
    function payFee(address payer) external payable {
        uint256 fee = _getFee();

        if (fee > msg.value) {
            revert Errors.InsufficientFee();
        }

        fees[session] += msg.value;

        emit FeePaid(payer, msg.value);
    }

    /// @notice Receives a cross-chain message from the Router contract.
    /// @param message The Equito message received.
    function receiveMessage(EquitoMessage calldata message) external override onlySovereign(message) {
        // Decode and handle the message based on the first byte
        bytes1 operation = message.data[0];
        if (operation == 0x01) {
            // Update the validator set
            address[] memory newValidators;
            bytes memory proof;
            (newValidators, proof) = abi.decode(message.data[1:], (address[], bytes));
            updateValidators(newValidators, proof);
        } else if (operation == 0x02) {
            // Update the message cost
            uint256 newMessageCostUsd;
            (newMessageCostUsd) = abi.decode(message.data[1:], (uint256));
            _setMessageCostUsd(newMessageCostUsd);
        } else if (operation == 0x03) {
            // Transfer fees to the liquidity provider
            address liquidityProvider;
            uint256 amount;
            (liquidityProvider, amount) = abi.decode(message.data[1:], (address, uint256));
            
            transferFees(liquidityProvider, amount);
        } else {
            revert Errors.InvalidOperation();
        }
    }

    /// @notice Transfers fees to the liquidity provider.
    /// @param liquidityProvider The address of the liquidity provider.
    /// @param amount The amount of fees to transfer.
    function transferFees(address liquidityProvider, uint256 amount) internal {
        payable(liquidityProvider).transfer(amount);
        emit FeesTransferred(liquidityProvider, session, amount);
    }

    /// @notice Calculates the fee amount required to send a message based on the current messageCostUsd and tokenPriceUsd from the Oracle.
    /// @return The fee amount in wei.
    function _getFee() internal view returns (uint256) {
        uint256 tokenPriceUsd = oracle.getTokenPriceUsd();
        if (tokenPriceUsd == 0) {
            revert Errors.InvalidTokenPriceFromOracle();
        }

        return messageCostUsd / tokenPriceUsd;
    }

    /// @notice Sets the cost of sending a message in USD.
    /// @param _messageCostUsd The new cost of sending a message in USD.
    function _setMessageCostUsd(uint256 _messageCostUsd) internal {
        if (_messageCostUsd == 0) {
            revert Errors.CostMustBeGreaterThanZero();
        }

        messageCostUsd = _messageCostUsd;
        emit MessageCostUsdSet(_messageCostUsd);
    }
}
