#!/bin/bash

SEPOLIA_RPC_URL=localhost:8545
BNB_RPC_URL=localhost:8546
POLYGON_RPC_URL=localhost:8547

PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ACCOUNTS="[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266]"

echo "Starting deployment..."

# Deploy Verifier on Sepolia
SEPOLIA_VERIFIER=$( forge create src/ECDSAVerifier.sol:ECDSAVerifier \
    --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --constructor-args $ACCOUNTS | \
    grep "Deployed to:" | awk '/0x.*/ {print $3}' )

# Deploy Router on Sepolia
SEPOLIA_ROUTER=$( forge create src/Router.sol:Router \
    --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --constructor-args 1 $SEPOLIA_VERIFIER | \
    grep "Deployed to:" | awk '/0x.*/ {print $3}' )

echo "Router contract deployed on Sepolia at $SEPOLIA_ROUTER"

# Deploy Verifier on BNB Testnet
BNB_VERIFIER=$( forge create src/ECDSAVerifier.sol:ECDSAVerifier \
    --rpc-url $BNB_RPC_URL --private-key $PRIVATE_KEY --constructor-args $ACCOUNTS | \
    grep "Deployed to:" | awk '/0x.*/ {print $3}' )

# Deploy Router on BNB Testnet
BNB_ROUTER=$( forge create src/Router.sol:Router \
    --rpc-url $BNB_RPC_URL --private-key $PRIVATE_KEY --constructor-args 2 $BNB_VERIFIER | \
    grep "Deployed to:" | awk '/0x.*/ {print $3}' )

echo "Router contract deployed on BNB Testnet at $BNB_ROUTER"


# Deploy Verifier on BNB Testnet
POLYGON_VERIFIER=$( forge create src/ECDSAVerifier.sol:ECDSAVerifier \
    --rpc-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY --constructor-args $ACCOUNTS | \
    grep "Deployed to:" | awk '/0x.*/ {print $3}' )

# Deploy on Polygon Testnet
POLYGON_ROUTER=$( forge create src/Router.sol:Router \
    --rpc-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY --constructor-args 3 $POLYGON_VERIFIER | \
    grep "Deployed to:" | awk '/0x.*/ {print $3}' )

echo "Router contract deployed on Polygon Testnet at $POLYGON_ROUTER"


# Generate dev.yml

echo "Generating dev.yml..."

cd "$(dirname "$0")" && cd ../../

echo "private-key: $PRIVATE_KEY" > out/dev.yml
echo "evm:" >> out/dev.yml

if [[ $SEPOLIA_ROUTER ]]; then
    echo "  - chain: Sepolia" >> out/dev.yml
    echo "    id: 11155111" >> out/dev.yml
    echo "    endpoint: ${SEPOLIA_RPC_URL}" >> out/dev.yml
    echo "    router: ${SEPOLIA_ROUTER}" >> out/dev.yml
    echo "    block: 1" >> out/dev.yml
fi
if [[ $BNB_ROUTER ]]; then
    echo "  - chain: BNB Testnet" >> out/dev.yml
    echo "    id: 97" >> out/dev.yml
    echo "    endpoint: ${BNB_RPC_URL}" >> out/dev.yml
    echo "    router: ${BNB_ROUTER}" >> out/dev.yml
    echo "    block: 1" >> out/dev.yml
fi
if [[ $POLYGON_ROUTER ]]; then
    echo "  - chain: Polygon Testnet" >> out/dev.yml
    echo "    id: 80001" >> out/dev.yml
    echo "    endpoint: ${POLYGON_RPC_URL}" >> out/dev.yml
    echo "    router: ${POLYGON_ROUTER}" >> out/dev.yml
    echo "    block: 1" >> out/dev.yml
fi

echo "Deployment completed."