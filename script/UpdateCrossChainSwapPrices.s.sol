// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {CrossChainSwap} from "../src/examples/CrossChainSwap.sol";
import {MockERC20} from "../src/examples/MockERC20.sol";

/// This script is used to update prices to the CrossChainSwap contract using the configuration determined by the env file.
contract UpdateCrossChainSwapPrices is Script {
    address public crossChainSwap = vm.envAddress("CROSS_CHAIN_SWAP");

    uint256 public UNIT = 1_000;

    function run() public {
        // start broadcasting transactions
        vm.startBroadcast();

        console.log("======== Update CrossChainSwap Prices =========");

        CrossChainSwap swap = CrossChainSwap(crossChainSwap);

        uint256[] memory chainSelectors = new uint256[](18);
        chainSelectors[0] = 1; // Ethereum Sepolia
        chainSelectors[1] = 1; // Ethereum Sepolia
        chainSelectors[2] = 2; // BSC Testnet
        chainSelectors[3] = 2; // BSC Testnet
        chainSelectors[4] = 3; // Polygon Amoy
        chainSelectors[5] = 3; // Polygon Amoy
        chainSelectors[6] = 4; // Arbitrum Sepolia
        chainSelectors[7] = 4; // Arbitrum Sepolia
        chainSelectors[8] = 5; // Avalanche Fuji
        chainSelectors[9] = 5; // Avalanche Fuji
        chainSelectors[10] = 6; // Optimism Sepolia
        chainSelectors[11] = 6; // Optimism Sepolia
        chainSelectors[12] = 7; // Base Sepolia
        chainSelectors[13] = 7; // Base Sepolia
        chainSelectors[14] = 8; // Fantom Testnet
        chainSelectors[15] = 8; // Fantom Testnet
        chainSelectors[16] = 9; // Celo Alfajores
        chainSelectors[17] = 9; // Celo Alfajores

        bytes[] memory destinationTokens = new bytes[](18);
        destinationTokens[0] = abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // ETH
        destinationTokens[1] = abi.encode(0x515C53914aFC9071Cd5ee62E1e58001A4c2A525b); // DAI
        destinationTokens[2] = abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // BNB
        destinationTokens[3] = abi.encode(0xca0BfbdA7a627E42cef246286f1A208c32362c34); // BUSD
        destinationTokens[4] = abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // MATIC
        destinationTokens[5] = abi.encode(0xdb0e6b300c14349F3094b989cB14B719671B2C35); // USDC
        destinationTokens[6] = abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // ETH
        destinationTokens[7] = abi.encode(0xdb0e6b300c14349F3094b989cB14B719671B2C35); // USDC
        destinationTokens[8] = abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // AVAX
        destinationTokens[9] = abi.encode(0xdb0e6b300c14349F3094b989cB14B719671B2C35); // USDC
        destinationTokens[10] = abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // ETH
        destinationTokens[11] = abi.encode(0xdb0e6b300c14349F3094b989cB14B719671B2C35); // USDC
        destinationTokens[12] = abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // ETH
        destinationTokens[13] = abi.encode(0xdb0e6b300c14349F3094b989cB14B719671B2C35); // USDC
        destinationTokens[14] = abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // FTM
        destinationTokens[15] = abi.encode(0xdb0e6b300c14349F3094b989cB14B719671B2C35); // USDC
        destinationTokens[16] = abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // CELO
        destinationTokens[17] = abi.encode(0xdb0e6b300c14349F3094b989cB14B719671B2C35); // USDC

        uint256[] memory prices = new uint256[](18);
        prices[0] = 3000 * UNIT; // ETH
        prices[1] = 1 * UNIT; // DAI
        prices[2] = 600 * UNIT; // BNB
        prices[3] = 1 * UNIT; // BUSD
        prices[4] = (8 * UNIT) / 10; // MATIC
        prices[5] = 1 * UNIT; // USDC
        prices[6] = 3000 * UNIT; // ETH
        prices[7] = 1 * UNIT; // USDC
        prices[8] = 30 * UNIT; // AVAX
        prices[9] = 1 * UNIT; // USDC
        prices[10] = 3000 * UNIT; // ETH
        prices[11] = 1 * UNIT; // USDC
        prices[12] = 3000 * UNIT; // ETH
        prices[13] = 1 * UNIT; // USDC
        prices[14] = (7 * UNIT) / 10; // FTM
        prices[15] = 1 * UNIT; // USDC
        prices[16] = (7 * UNIT) / 10; // CELO
        prices[17] = 1 * UNIT; // USDC
        
        swap.setTokenPrice(chainSelectors, destinationTokens, prices);

        console.log("======== Finished update process =========");

        console.log(
            "ETH price in UNITs =>",
            swap.tokenPrice(
                1,
                abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            )
        );

        console.log(
            "AVAX price in UNITs =>",
            swap.tokenPrice(
                5,
                abi.encode(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            )
        );

        // finish broadcasting transactions
        vm.stopBroadcast();
    }
}
