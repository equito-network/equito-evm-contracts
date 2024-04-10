// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

library Client {
    struct EquitoMessage {
        uint256 nonce; // Nonce of the message.
        uint256 sourceChainSelector; // Source chain selector.
        bytes sender; // abi.decode(sender) if coming from an EVM chain.
        uint256 destinationChainSelector; // Destination chain selector.
        address receiver; // Receiver address
        bytes data; // payload sent in original message.
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
                            original.nonce
                        )
                    ),
                    keccak256(original.data)
                )
            );
    }
}
