// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

library EquitoMessageLibrary {
    /// The ubiquitous message structure for cross-chain communication,
    /// used by the Router contract to deliver and receive messages.
    /// It's designed to be used by any chain supported by the Equito protocol.
    struct EquitoMessage {
        /// Block number at which the message is emitted.
        uint256 blockNumber;
        // Selector for the source chain, acting as an id.
        uint256 sourceChainSelector;
        // Address of the sender.
        bytes sender;
        // Selector for the destination chain, acting as an id.
        uint256 destinationChainSelector;
        // Address of the receiver.
        bytes receiver;
        // Encoded payload of the message to be delivered.
        bytes data;
    }

    function _hash(
        EquitoMessage memory original
    ) internal pure returns (bytes32) {
        // Fixed-size message fields are included in nested hash to reduce stack pressure.
        // This hashing scheme is also used by RMN. If changing it, please notify the RMN maintainers.
        return
            keccak256(
                abi.encode(
                    keccak256(
                        abi.encode(
                            original.sender,
                            original.receiver,
                            original.blockNumber,
                            original.sourceChainSelector,
                            original.destinationChainSelector
                        )
                    ),
                    keccak256(original.data)
                )
            );
    }
}
