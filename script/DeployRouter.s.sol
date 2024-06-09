// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";

import {Router} from "../src/Router.sol";
import {ECDSAVerifier} from "../src/ECDSAVerifier.sol";
import {IEquitoFees} from "../src/interfaces/IEquitoFees.sol";
import {IOracle} from "../src/interfaces/IOracle.sol";
import {EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";

/// This script is used to deploy the Router contract using the configuration determined by the env file.
contract DeployRouter is Script {
    using stdJson for string;

    uint256 public chainSelector = vm.envUint("CHAIN_SELECTOR");
    string public outputFilename = vm.envString("OUTPUT_FILENAME");
    address public equitoAddress = vm.envAddress("EQUITO_ADDRESS");

    ECDSAVerifier public verifier;
    Router public router;
    IOracle public oracle;

    address constant ALITH = 0xf24FF3a9CF04c71Dbc94D0b566f7A27B94566cac;
    address constant BALTATHAR = 0x3Cd0A705a2DC65e5b1E1205896BaA2be8A07c6e0;
    address constant CHARLETH = 0x798d4Ba9baf0064Ec19eB4F0a1a45785ae9D6DFc;

    function run() public {
        string memory root = vm.projectRoot();
        string memory basePath = string.concat(root, "/script/deployment/");
        // start broadcasting transactions
        vm.startBroadcast();

        address[] memory validators = new address[](3);
        validators[0] = ALITH;
        validators[1] = BALTATHAR;
        validators[2] = CHARLETH;

        console.log("======== Deploying ECDSAVerifier Verifier =========");
        verifier = new ECDSAVerifier(
            validators,
            0,
            address(oracle)
        );
        console.log(
            "Deployed ECDSAVerifier Verifier successfully =>",
            address(verifier)
        );

        console.log("======== Deploying Router =========");
        router = new Router(
            chainSelector,
            address(verifier),
            address(verifier),
            EquitoMessageLibrary.addressToBytes64(address(0x45717569746f))
        );
        console.log("Deployed Router successfully =>", address(router));

        console.log("======== Setting Router in ECDSAVerifier =========");
        verifier.setRouter(address(router));
        console.log("Set Router in ECDSAVerifier successfully");

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
