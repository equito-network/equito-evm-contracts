#!/bin/bash

SEPOLIA_RPC_URL=http://localhost:8545
BNB_RPC_URL=http://localhost:8546
POLYGON_RPC_URL=http://localhost:8547

SEPOLIA_CHAIN_SELECTOR=1
BNB_CHAIN_SELECTOR=2
POLYGON_CHAIN_SELECTOR=3

PRIVATE_KEY_DEPLOY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Deploy on sepolia
forge create src/Router.sol:Router --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY_DEPLOY --constructor-args $SEPOLIA_CHAIN_SELECTOR

# Deploy on bnb
forge create src/Router.sol:Router --rpc-url $BNB_RPC_URL --private-key $PRIVATE_KEY_DEPLOY --constructor-args $BNB_CHAIN_SELECTOR

# Deploy on polygon
forge create src/Router.sol:Router --rpc-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY_DEPLOY --constructor-args $POLYGON_CHAIN_SELECTOR