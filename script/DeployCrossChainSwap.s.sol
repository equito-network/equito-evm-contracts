// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";

import {Router} from "../src/Router.sol";
import {CrossChainSwap} from "../src/examples/CrossChainSwap.sol";
import {MockERC20} from "../src/examples/MockERC20.sol";

/// This script is used to deploy the Router contract using the configuration determined by the env file.
contract DeployCrossChainSwap is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    uint256 public chainSelector = vm.envUint("CHAIN_SELECTOR");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);

    CrossChainSwap public swap;
    MockERC20 public usdc;

    address router = 0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac;

    function run() public {
        // start broadcasting transactions
        vm.startBroadcast(deployerAddress);

        console.log("======== Deploying CrossChainSwap =========");
        swap = new CrossChainSwap(router);
        console.log("Deployed CrossChainSwap successfully =>", address(swap));

        console.log("======== Deploying USDC =========");
        usdc = new MockERC20("USDC", "USDC", 10_000_000 * 1e6);
        console.log("Deployed USDC successfully =>", address(usdc));

        console.log(
            "======== Transfer USDC to Cross Chain Swap for liquidity ========="
        );

        usdc.transfer(address(swap), 1_000_000 * 1e6);

        console.log(
            "======== Transfer Native to Chain Swap for liquidity ========="
        );

        (bool success, ) = address(swap).call{value: 0.001 * 1 ether}("");
        if (!success) {
            console.log("Failed to transfer native to CrossChainSwap");
        }

        console.log("======== Finished deploy process =========");

        // finish broadcasting transactions
        vm.stopBroadcast();
    }
}
