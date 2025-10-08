# 🚀 Quick Start - Deploy in 5 Minutes

## Step 1: Get Requirements (2 minutes)

### A. Get Sepolia RPC URL (FREE)
1. Go to https://www.alchemy.com/
2. Sign up (free)
3. Create New App → Ethereum → Sepolia
4. Copy the HTTPS URL

### B. Export Your Private Key
1. Open MetaMask
2. Click account → Account Details
3. Export Private Key
4. Copy it (starts with `0x`)

### C. Get Sepolia ETH (FREE)
Get ~0.1 ETH from any faucet:
- https://sepoliafaucet.com/
- https://www.infura.io/faucet/sepolia
- https://faucet.quicknode.com/ethereum/sepolia

## Step 2: Configure (1 minute)

```bash
# Edit the .env file
nano .env

# Replace these 3 values:
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
PRIVATE_KEY=0xYOUR_PRIVATE_KEY
ETHERSCAN_API_KEY=YOUR_KEY  # Optional
```

## Step 3: Deploy (2 minutes)

```bash
# One command deployment!
./deploy.sh
```

That's it! 🎉

## What Gets Deployed?

✅ **MockMToken** - Test M token with earning  
✅ **MockSwapFacility** - Wrap/unwrap facility  
✅ **MockPrizeDistributor** - Yield receiver  
✅ **MYieldToPrizeDistributor** - Your extension (UUPS proxy)

## After Deployment

You'll get:
- 📍 All contract addresses
- 💻 Ready-to-use test commands
- 🔍 Etherscan links

## Next Steps

1. **Save the contract addresses** (printed by script)
2. **Test on testnet** with provided commands
3. **View on Etherscan** to verify deployment

## Troubleshooting

### "Insufficient funds"
→ Get more Sepolia ETH from faucets

### "RPC URL not working"
→ Check your Alchemy/Infura URL is correct

### "Private key invalid"
→ Make sure it starts with `0x` and is 66 characters

## Manual Deployment

If you prefer step-by-step:

```bash
# 1. Verify setup
./verify-setup.sh

# 2. Deploy
source .env
forge script script/DeployWithMocks.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

## Files Created

- ✅ `.env` - Your configuration
- ✅ `deploy.sh` - One-command deployment
- ✅ `verify-setup.sh` - Setup verification
- ✅ `script/DeployWithMocks.s.sol` - Deployment script

---

**Need help?** Check the error message and run `./verify-setup.sh` to diagnose.

**Ready?** → `./deploy.sh` 🚀

