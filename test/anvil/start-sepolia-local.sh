#!/bin/bash

PORT=8545
RPC_URL=http://localhost:8545
CHAIN_ID=11155111
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

anvil --port $PORT --chain-id $CHAIN_ID --init $(pwd)/test/config/sepolia-genesis.json

# forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY --constructor-args $CHAIN_ID src/Router.sol:Router