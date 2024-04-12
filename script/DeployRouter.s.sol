// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";

import {Router} from "../src/Router.sol";

/// This script is used to deploy the Router contract by add config from env files.
contract DeployRouter is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    uint256 public chainSelector = vm.envUint("CHAIN_SELECTOR");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public outputFilename = vm.envString("OUTPUT_FILENAME");

    Router public router;

    function run() public {
        string memory root = vm.projectRoot();
        string memory basePath = string.concat(root, "/script/deployment/");
        // start broadcasting transactions
        vm.startBroadcast(deployerAddress);

        console.log("======== Deploying Router =========");
        router = new Router(chainSelector);
        console.log("Deployed Router successfully =>", address(router));

        console.log("======== Finished deploy process =========");

        // finish broadcasting transactions
        vm.stopBroadcast();

        // Write to file
        string memory path = string.concat(basePath, outputFilename);
        vm.writeJson(
            vm.serializeAddress("contracts", "router", address(router)),
            path
        );
    }
}
