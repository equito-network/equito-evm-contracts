// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";

import {Router} from "../src/Router.sol";

contract SendMessage is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    address public routerContract = vm.envAddress("ROUTER_CONTRACT");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);

    Router public router;

    bytes public receiver = "";
    uint256 public destinationChainSelector = 0;
    bytes public data = abi.encodePacked("Hello, World!");

    function run() public {
        router = Router(routerContract);

        // start broadcasting transactions
        vm.startBroadcast(deployerAddress);

        console.log("======== Sending message =========");

        // Construct parameters

        router.sendMessage(receiver, destinationChainSelector, data);

        console.log("======== Message sent =========");

        // finish broadcasting transactions
        vm.stopBroadcast();
    }
}
