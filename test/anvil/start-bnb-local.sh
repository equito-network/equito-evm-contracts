#!/bin/bash

PORT=8546
RPC_URL=http://localhost:8546
CHAIN_ID=97
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

anvil --port $PORT --chain-id $CHAIN_ID --init $(pwd)/test/config/bnb-genesis.json
