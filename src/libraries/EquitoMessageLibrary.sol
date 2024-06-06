// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

/// @title EquitoMessage
/// @notice The ubiquitous message structure for cross-chain communication, used by the Router contract to deliver and receive messages.
/// @dev Designed to be used by any chain supported by the Equito protocol.
struct EquitoMessage {
    /// @notice Block number at which the message is emitted.
    uint256 blockNumber;
    /// @notice Selector for the source chain, acting as an id.
    uint256 sourceChainSelector;
    /// @notice Address of the sender.
    bytes sender;
    /// @notice Selector for the destination chain, acting as an id.
    uint256 destinationChainSelector;
    /// @notice Address of the receiver.
    bytes receiver;
    /// @notice Encoded payload of the message to be delivered.
    bytes data;
}

/// @title EquitoMessageLibrary
/// @notice Library providing helper functions for EquitoMessage struct.
/// @dev Contains hashing function for EquitoMessage.
library EquitoMessageLibrary {

    /// @notice Computes the keccak256 hash of an EquitoMessage.
    /// @param original The EquitoMessage struct to hash.
    /// @return The keccak256 hash of the EquitoMessage.
    /// @dev Fixed-size message fields are included in nested hash to reduce stack pressure.
    /// This hashing scheme is also used by RMN. If changing it, please notify the RMN maintainers.
    function _hash(
        EquitoMessage memory original
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    keccak256(
                        abi.encodePacked(
                            original.blockNumber,
                            original.sourceChainSelector,
                            original.destinationChainSelector
                        )
                    ),
                    keccak256(original.sender),
                    keccak256(original.receiver),
                    keccak256(original.data)
                )
            );
    }
}
