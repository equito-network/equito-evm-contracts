// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    // Directly call the token contract to approve
    function safeApprove(address token, address to, uint256 value) internal {
        // The signature function is bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        // Check if the call was successful and the data is empty or the data is a boolean value
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    // Directly call the token contract to transfer
    function safeTransfer(address token, address to, uint256 value) internal {
        // The signature function is bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        // Check if the call was successful and the data is empty or the data is a boolean value
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    // Directly call the token contract to transferFrom
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // The signature function is bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        // Check if the call was successful and the data is empty or the data is a boolean value
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    // Directly call the token contract to transfer
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        // Check if the call was successful
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}
