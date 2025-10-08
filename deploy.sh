#!/bin/bash

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    🚀 DEPLOYING TO SEPOLIA TESTNET                           ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo ""
    echo "Please create it first:"
    echo "  1. Copy template: cp .env.template .env"
    echo "  2. Edit with your values: nano .env"
    echo "  3. Run this script again"
    exit 1
fi

# Source .env
source .env

# Verify setup
echo "🔍 Verifying setup..."
./verify-setup.sh
if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Setup verification failed!"
    echo "Please fix the issues above and try again."
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "📦 Starting deployment with mocks..."
echo ""

# Run deployment
forge script script/DeployWithMocks.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    -vvvv

if [ $? -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                       ✅ DEPLOYMENT SUCCESSFUL!                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 Next steps:"
    echo "  1. Save the contract addresses from above"
    echo "  2. Run test scripts to interact with deployed contracts"
    echo "  3. Check on Sepolia Etherscan"
    echo ""
else
    echo ""
    echo "❌ Deployment failed!"
    echo ""
    echo "Common issues:"
    echo "  • Insufficient Sepolia ETH (get from faucet)"
    echo "  • Invalid RPC URL"
    echo "  • Network connectivity"
    echo ""
fi

