#!/bin/bash

SEPOLIA_RPC_URL=http://localhost:8545
BNB_RPC_URL=http://localhost:8546
POLYGON_RPC_URL=http://localhost:8547

CHAIN_ID_SEPOLIA=11155111
CHAIN_ID_BNB=97
CHAIN_ID_POLYGON=80001

PRIVATE_KEY_DEPLOY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Deploy on sepolia
forge create src/Router.sol:Router --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY_DEPLOY --constructor-args $CHAIN_ID_SEPOLIA

# Deploy on bnb
forge create src/Router.sol:Router --rpc-url $BNB_RPC_URL --private-key $PRIVATE_KEY_DEPLOY --constructor-args $CHAIN_ID_BNB

# Deploy on polygon
forge create src/Router.sol:Router --rpc-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY_DEPLOY --constructor-args $CHAIN_ID_POLYGON