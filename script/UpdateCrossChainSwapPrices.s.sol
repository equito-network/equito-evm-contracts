// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {CrossChainSwap} from "../src/examples/CrossChainSwap.sol";
import {MockERC20} from "../src/examples/MockERC20.sol";

/// This script is used to update prices to the CrossChainSwap contract using the configuration determined by the env file.
contract UpdateCrossChainSwapPrices is Script {
    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);

    address public crossChainSwap = vm.envAddress("CROSS_CHAIN_SWAP");
    address public mockErc20 = vm.envAddress("MOCK_ERC20");

    uint256 public UNIT = 1_000;

    function run() public {
        // start broadcasting transactions
        vm.startBroadcast(deployerAddress);

        console.log("======== Update CrossChainSwap Prices =========");

        CrossChainSwap swap = CrossChainSwap(crossChainSwap);

        uint256[] memory chainSelectors = new uint256[](6);

        chainSelectors[0] = 1;
        chainSelectors[1] = 1;
        chainSelectors[2] = 2;
        chainSelectors[3] = 2;
        chainSelectors[4] = 3;
        chainSelectors[5] = 3;

        bytes[] memory destinationTokens = new bytes[](6);

        destinationTokens[0] = abi.encode(
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        );
        destinationTokens[1] = abi.encode(mockErc20);
        destinationTokens[2] = abi.encode(
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        );
        destinationTokens[3] = abi.encode(mockErc20);
        destinationTokens[4] = abi.encode(
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        );
        destinationTokens[5] = abi.encode(mockErc20);

        uint256[] memory prices = new uint256[](6);

        prices[0] = 3_000 * UNIT; // ETH
        prices[1] = 1 * UNIT; // USDC
        prices[2] = 600 * UNIT; // BNB
        prices[3] = 1 * UNIT; // BUSD
        prices[4] = (8 * UNIT) / 10; // MATIC
        prices[5] = 1 * UNIT; // USDC

        swap.setTokenPrice(chainSelectors, destinationTokens, prices);

        console.log("======== Finished update process =========");

        console.log(
            swap.tokenPrice(
                1,
                abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            )
        );

        // finish broadcasting transactions
        vm.stopBroadcast();
    }
}
