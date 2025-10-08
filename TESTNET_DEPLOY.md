# 🚀 Testnet Deployment Guide

## Step 1: Get M0 Testnet Addresses

You need M0's testnet addresses. Check:
- **M0 Discord**: Ask for Sepolia testnet addresses
- **M0 Docs**: https://docs.m0.org/deployment-addresses
- **M0 GitHub**: https://github.com/m0-foundation

## Step 2: Deploy Your PrizeDistributor (if needed)

If you don't have a PrizeDistributor yet, deploy the mock one:

```bash
forge create test/mocks/MockPrizeDistributor.sol:MockPrizeDistributor \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify
```

Save the deployed address!

## Step 3: Create .env File

Create `.env` in the project root:

```bash
# RPC URL (get from Alchemy, Infura, or QuickNode)
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY

# Your private key (KEEP SECRET!)
PRIVATE_KEY=0xYOUR_PRIVATE_KEY

# Etherscan API key (for verification)
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY

# M0 Sepolia addresses (GET FROM M0 TEAM)
SEPOLIA_M_TOKEN=0x...
SEPOLIA_SWAP_FACILITY=0x...

# Your addresses
PRIZE_DISTRIBUTOR=0x...  # From Step 2
ADMIN=0x...              # Your multisig or EOA
FREEZE_MANAGER=0x...     # Your multisig or EOA
YIELD_RECIPIENT_MANAGER=0x...  # Your governance address
```

## Step 4: Update Deploy Script

Edit `script/Deploy.s.sol` and replace placeholder addresses:

```solidity
// Line 14-15
address constant SEPOLIA_M_TOKEN = 0x...;  // From M0
address constant SEPOLIA_SWAP_FACILITY = 0x...;  // From M0

// Line 28-31
address constant PRIZE_DISTRIBUTOR = 0x...;  // Your PrizeDistributor
address constant ADMIN = 0x...;  // Your admin
address constant FREEZE_MANAGER = 0x...;  // Your freeze manager
address constant YIELD_RECIPIENT_MANAGER = 0x...;  // Your governance
```

## Step 5: Test Compilation

```bash
forge build
```

## Step 6: Deploy to Sepolia

```bash
source .env

forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  -vvvv
```

## Step 7: Verify Deployment

Check Sepolia Etherscan for:
- ✅ Proxy deployed
- ✅ Implementation deployed
- ✅ Contracts verified
- ✅ Initialization successful

## Step 8: Apply for M0 Earner Approval

Contact M0 team with:
- Your extension address
- Description of use case
- Security measures

## Step 9: Enable Earning (after approval)

Once M0 approves your extension:

```bash
cast send YOUR_EXTENSION_ADDRESS \
  "enableEarning()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

## Step 10: Test the Extension

Run the test script against deployed contract (we'll do this next!)

---

**Ready to deploy? Let me know if you have all the addresses!**

