#!/bin/bash

SEPOLIA_RPC_URL=localhost:8545
BNB_RPC_URL=localhost:8546
POLYGON_RPC_URL=localhost:8547

PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

echo "Starting deployment..."

# Deploy on Ethereum Sepolia
SEPOLIA_ROUTER=$( CHAIN_SELECTOR=1 TOKEN_PRICE_USD=3500000 \
    EQUITO_ADDRESS=0x134dD08ce347b8F67810addBD87Cafa3441567a8 \
    VALIDATORS=0x2120C64a01260D6819bd01FABe5844EE07B8c33F,0xD42086961E21BC9895E649CE421b8328655D962D \
    forge script DeployRouter --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY | \
    grep "Deployed Router" | awk '/0x.*/ {print $5}' )

if [[ $SEPOLIA_ROUTER ]]; then
    echo "Router contract deployed on Ethereum Sepolia at $SEPOLIA_ROUTER"
else 
    echo "Failed to deploy Router contract on Ethereum Sepolia"
fi

# Deploy on BNB Testnet
BNB_ROUTER=$( CHAIN_SELECTOR=2 TOKEN_PRICE_USD=600000 \
    EQUITO_ADDRESS=0x134dD08ce347b8F67810addBD87Cafa3441567a8 \
    VALIDATORS=0x2120C64a01260D6819bd01FABe5844EE07B8c33F,0xD42086961E21BC9895E649CE421b8328655D962D \
    forge script DeployRouter --rpc-url $BNB_RPC_URL --private-key $PRIVATE_KEY | \
    grep "Deployed Router" | awk '/0x.*/ {print $5}' )

if [[ $BNB_ROUTER ]]; then 
    echo "Router contract deployed on BNB Testnet at $BNB_ROUTER"
else 
    echo "Failed to deploy Router contract on BNB Testnet"
fi

# Deploy on Polygon Testnet
POLYGON_ROUTER=$( CHAIN_SELECTOR=3 TOKEN_PRICE_USD=650 \
    EQUITO_ADDRESS=0x134dD08ce347b8F67810addBD87Cafa3441567a8 \
    VALIDATORS=0x2120C64a01260D6819bd01FABe5844EE07B8c33F,0xD42086961E21BC9895E649CE421b8328655D962D \
    forge script DeployRouter --rpc-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY | \
    grep "Deployed Router" | awk '/0x.*/ {print $5}' )

if [[ $POLYGON_ROUTER ]]; then 
    echo "Router contract deployed on Polygon Testnet at $POLYGON_ROUTER"
else 
    echo "Failed to deploy Router contract on Polygon Testnet"
fi

# Generate dev.yml

echo "Generating dev.yml..."

cd "$(dirname "$0")" && cd ../../

echo "private-key: $PRIVATE_KEY" > out/dev.yml
echo "evm:" >> out/dev.yml

if [[ $SEPOLIA_ROUTER ]]; then
    echo "  - chain: Sepolia" >> out/dev.yml
    echo "    id: 11155111" >> out/dev.yml
    echo "    endpoint: ${SEPOLIA_RPC_URL}" >> out/dev.yml
fi
if [[ $BNB_ROUTER ]]; then
    echo "  - chain: BNB Testnet" >> out/dev.yml
    echo "    id: 97" >> out/dev.yml
    echo "    endpoint: ${BNB_RPC_URL}" >> out/dev.yml
fi
if [[ $POLYGON_ROUTER ]]; then
    echo "  - chain: Polygon Testnet" >> out/dev.yml
    echo "    id: 80001" >> out/dev.yml
    echo "    endpoint: ${POLYGON_RPC_URL}" >> out/dev.yml
fi

echo "Deployment completed."