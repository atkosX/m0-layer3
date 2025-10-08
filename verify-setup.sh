#!/bin/bash

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                      🔍 VERIFYING DEPLOYMENT SETUP                           ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "   Run: cp .env.template .env"
    exit 1
fi

# Source .env
source .env

# Check RPC URL
echo "1️⃣  Checking RPC URL..."
if [[ "$SEPOLIA_RPC_URL" == *"YOUR_API_KEY"* ]] || [ -z "$SEPOLIA_RPC_URL" ]; then
    echo "   ❌ SEPOLIA_RPC_URL not configured"
    echo "   👉 Get free RPC from: https://www.alchemy.com/"
    exit 1
else
    echo "   ✅ RPC URL configured"
    # Test RPC connection
    if curl -s -X POST $SEPOLIA_RPC_URL \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | grep -q "result"; then
        echo "   ✅ RPC connection working!"
    else
        echo "   ⚠️  RPC URL might be invalid"
    fi
fi

# Check Private Key
echo ""
echo "2️⃣  Checking Private Key..."
if [[ "$PRIVATE_KEY" == *"YOUR_PRIVATE_KEY"* ]] || [ -z "$PRIVATE_KEY" ]; then
    echo "   ❌ PRIVATE_KEY not configured"
    echo "   👉 Export from MetaMask: Account Details > Export Private Key"
    exit 1
else
    echo "   ✅ Private key configured"
    
    # Get address from private key
    ADDRESS=$(cast wallet address $PRIVATE_KEY 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "   📍 Deployer address: $ADDRESS"
        
        # Check balance
        BALANCE=$(cast balance $ADDRESS --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
        if [ $? -eq 0 ]; then
            BALANCE_ETH=$(cast --to-unit $BALANCE ether 2>/dev/null)
            echo "   💰 Balance: $BALANCE_ETH ETH"
            
            # Check if sufficient
            if (( $(echo "$BALANCE_ETH < 0.05" | bc -l) )); then
                echo "   ⚠️  Low balance! Get Sepolia ETH from:"
                echo "      • https://sepoliafaucet.com/"
                echo "      • https://www.infura.io/faucet/sepolia"
            else
                echo "   ✅ Sufficient balance for deployment"
            fi
        fi
    fi
fi

# Check Etherscan API Key (optional)
echo ""
echo "3️⃣  Checking Etherscan API Key..."
if [[ "$ETHERSCAN_API_KEY" == *"YOUR_ETHERSCAN"* ]] || [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "   ⚠️  Etherscan API key not configured (optional)"
    echo "   👉 Get free key: https://etherscan.io/myapikey"
    echo "   📝 Contracts can still be verified manually"
else
    echo "   ✅ Etherscan API key configured"
fi

# Check Forge installation
echo ""
echo "4️⃣  Checking Foundry installation..."
if command -v forge &> /dev/null; then
    FORGE_VERSION=$(forge --version | head -1)
    echo "   ✅ $FORGE_VERSION"
else
    echo "   ❌ Forge not found"
    echo "   👉 Install: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                         ✅ SETUP VERIFICATION COMPLETE                       ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "🚀 Ready to deploy!"
echo ""
echo "Run this command:"
echo "  forge script script/DeployWithMocks.s.sol \\"
echo "    --rpc-url \$SEPOLIA_RPC_URL \\"
echo "    --broadcast \\"
echo "    --verify \\"
echo "    -vvvv"
echo ""

