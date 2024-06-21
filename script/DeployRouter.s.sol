// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "forge-std/StdJson.sol";
import "forge-std/Script.sol";

import {Router} from "../src/Router.sol";
import {ECDSAVerifier} from "../src/ECDSAVerifier.sol";
import {IEquitoFees} from "../src/interfaces/IEquitoFees.sol";
import {IOracle} from "../src/interfaces/IOracle.sol";
import {EquitoMessageLibrary} from "../src/libraries/EquitoMessageLibrary.sol";
import {MockOracle} from "../test/mock/MockOracle.sol";

/// This script is used to deploy the Router contract using the configuration determined by the env file.
contract DeployRouter is Script {
    using stdJson for string;

    uint256 public chainSelector = vm.envUint("CHAIN_SELECTOR");
    address public equitoAddress = vm.envAddress("EQUITO_ADDRESS");
    address[] public validators = vm.envAddress("VALIDATORS", ",");

    // Token price in USD with 3 decimals
    uint256 public tokenPriceUSD = vm.envUint("TOKEN_PRICE_USD");

    ECDSAVerifier public verifier;
    Router public router;
    IOracle public oracle;


    function run() public {
        // start broadcasting transactions
        vm.startBroadcast();

        console.log("======== Deploying Mock Oracle =========");
        oracle = new MockOracle(tokenPriceUSD * 1e15);
        console.log(
            "Deployed MockOracle successfully =>",
            address(verifier)
        );

        console.log("======== Deploying ECDSAVerifier =========");
        verifier = new ECDSAVerifier(
            validators,
            0,
            address(oracle)
        );
        console.log(
            "Deployed ECDSAVerifier successfully =>",
            address(verifier)
        );

        console.log("======== Deploying Router =========");
        router = new Router(
            chainSelector,
            address(verifier),
            address(verifier),
            EquitoMessageLibrary.addressToBytes64(equitoAddress)
        );
        console.log("Deployed Router successfully =>", address(router));

        console.log("======== Finished deploy process =========");

        // finish broadcasting transactions
        vm.stopBroadcast();
    }
}
