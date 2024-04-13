#!/bin/bash

PORT=8547
RPC_URL=http://localhost:8547
CHAIN_ID=80001
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

anvil --port $PORT --chain-id $CHAIN_ID --init $(pwd)/test/config/polygon-genesis.json
