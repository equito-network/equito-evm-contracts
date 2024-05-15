#!/bin/bash

SEPOLIA_RPC_URL=localhost:8545
BNB_RPC_URL=localhost:8546
POLYGON_RPC_URL=localhost:8547

PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

ROUTER=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

echo "Starting deployment..."

SEPOLIA_CONTRACT=$( PRIVATE_KEY_DEPLOY=$PRIVATE_KEY ROUTER=$ROUTER CHAIN_SELECTOR=1 \
    forge script script/DeployCrossChainSwap.s.sol:DeployCrossChainSwap \
    --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast | \
    grep "Deployed CrossChainSwap successfully" | awk '/0x.*/ {print $5}' )

echo "Cross-Chain Swap contract deployed on Sepolia at $SEPOLIA_CONTRACT"

BNB_CONTRACT=$( PRIVATE_KEY_DEPLOY=$PRIVATE_KEY ROUTER=$ROUTER CHAIN_SELECTOR=2 \
    forge script script/DeployCrossChainSwap.s.sol:DeployCrossChainSwap \
    --rpc-url $BNB_RPC_URL --private-key $PRIVATE_KEY --broadcast | \
    grep "Deployed CrossChainSwap successfully" | awk '/0x.*/ {print $5}' )

echo "Cross-Chain Swap contract deployed on BNB Testnet at $BNB_CONTRACT"

POLYGON_CONTRACT=$( PRIVATE_KEY_DEPLOY=$PRIVATE_KEY ROUTER=$ROUTER CHAIN_SELECTOR=3 \
    forge script script/DeployCrossChainSwap.s.sol:DeployCrossChainSwap \
    --rpc-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY --broadcast | \
    grep "Deployed CrossChainSwap successfully" | awk '/0x.*/ {print $5}' )

echo "Cross-Chain Swap contract deployed on Polygon Testnet at $POLYGON_CONTRACT"


PRIVATE_KEY_DEPLOY=$PRIVATE_KEY CROSS_CHAIN_SWAP=$SEPOLIA_CONTRACT \
MOCK_ERC20=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 \
forge script script/UpdateCrossChainSwapPrices.s.sol:UpdateCrossChainSwapPrices \
--rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast

PRIVATE_KEY_DEPLOY=$PRIVATE_KEY CROSS_CHAIN_SWAP=$BNB_CONTRACT \
MOCK_ERC20=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 \
forge script script/UpdateCrossChainSwapPrices.s.sol:UpdateCrossChainSwapPrices \
--rpc-url $BNB_RPC_URL --private-key $PRIVATE_KEY --broadcast

PRIVATE_KEY_DEPLOY=$PRIVATE_KEY CROSS_CHAIN_SWAP=$POLYGON_CONTRACT \
MOCK_ERC20=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 \
forge script script/UpdateCrossChainSwapPrices.s.sol:UpdateCrossChainSwapPrices \
--rpc-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY --broadcast

echo "Deployment completed."
