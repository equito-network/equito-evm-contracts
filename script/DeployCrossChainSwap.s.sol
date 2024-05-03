// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {Router} from "../src/Router.sol";
import {CrossChainSwap} from "../src/examples/CrossChainSwap.sol";
import {MockERC20} from "../src/examples/MockERC20.sol";

/// This script is used to deploy the CrossChainSwap contract using the configuration determined by the env file.
contract DeployCrossChainSwap is Script {
    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    address public router = vm.envAddress("ROUTER");
    uint256 public chainSelector = vm.envUint("CHAIN_SELECTOR");

    CrossChainSwap public swap;
    MockERC20 public usdc;

    function run() public {
        // start broadcasting transactions
        vm.startBroadcast(deployerAddress);

        console.log("======== Deploying CrossChainSwap =========");
        swap = new CrossChainSwap{value: 1 ether}(router);
        console.log("Deployed CrossChainSwap successfully =>", address(swap));

        console.log("======== Deploying USDC =========");
        usdc = new MockERC20("USDC", "USDC", 10_000_000 * 1e18);
        console.log("Deployed USDC successfully =>", address(usdc));

        console.log(
            "======== Transfer USDC to Cross Chain Swap for liquidity ========="
        );

        usdc.transfer(address(swap), 1_000_000 * 1e18);
       
        console.log("======== Finished deploy process =========");

        // finish broadcasting transactions
        vm.stopBroadcast();
    }
}
