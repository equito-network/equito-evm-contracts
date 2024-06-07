// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";

import {Router} from "../src/Router.sol";
import {ECDSAVerifier} from "../src/ECDSAVerifier.sol";
import {IEquitoFees} from "../src/interfaces/IEquitoFees.sol";
import {IOracle} from "../src/interfaces/IOracle.sol";

/// This script is used to deploy the Router contract using the configuration determined by the env file.
contract DeployRouter is Script {
    using stdJson for string;

    uint256 public deployPrivateKey = vm.envUint("PRIVATE_KEY_DEPLOY");
    uint256 public chainSelector = vm.envUint("CHAIN_SELECTOR");
    address public deployerAddress = vm.rememberKey(deployPrivateKey);
    string public outputFilename = vm.envString("OUTPUT_FILENAME");

    ECDSAVerifier public verifier;
    Router public router;
    IOracle public oracle;

    address ALITH = 0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac;
    address BALTATHAR = 0x3Cd0A705a2DC65e5b1E1205896BaA2be8A07c6e0;
    address CHARLETH = 0x798d4Ba9baf0064Ec19eB4F0a1a45785ae9D6DFc;

    function run() public {
        string memory root = vm.projectRoot();
        string memory basePath = string.concat(root, "/script/deployment/");
        // start broadcasting transactions
        vm.startBroadcast(deployerAddress);

        address[] memory validators = new address[](3);
        validators[0] = ALITH;
        validators[1] = BALTATHAR;
        validators[2] = CHARLETH;

        console.log("======== Deploying ECDSAVerifier Verifier =========");
        verifier = new ECDSAVerifier(validators, 0, address(oracle), address(router), hex"45717569746f");
        console.log("Deployed ECDSAVerifier Verifier successfully =>", address(verifier));

        console.log("======== Deploying Router =========");
        router = new Router(chainSelector, address(verifier), address(verifier));
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
