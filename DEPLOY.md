# 🚀 M0 Extension Testnet Deployment

## 📋 Deployment Summary

**Network**: Sepolia Testnet (Chain ID: 11155111)  
**Deployment Date**: October 8, 2024  
**Status**: ✅ Successfully Deployed & Verified

## 🏗️ Contract Addresses

| Contract                             | Address                                      | Type               |
| ------------------------------------ | -------------------------------------------- | ------------------ |
| **MYieldToPrizeDistributor (Proxy)** | `0xF49149cf9C6e28CF7CE435cD0d7e3D190C9f4601` | Main Contract      |
| **Implementation**                   | `0xd25848d17D40a505ca27036a03554e12fBBd5D20` | Logic Contract     |
| **MockMToken**                       | `0xB53CE3b3221d5CFcD73671A8524EC82c147515f3` | Mock M Token       |
| **MockSwapFacility**                 | `0x1b68BFb49d21235b386c513a643C86e212A5DD9E` | Mock Swap Facility |
| **MockPrizeDistributor**             | `0x1F9B522Aa93C6E57daA223770F8eE3451D5732D3` | Yield Recipient    |

## 🔗 Etherscan Links

- **Main Contract**: https://sepolia.etherscan.io/address/0xf49149cf9c6e28cf7ce435cd0d7e3d190c9f4601
- **Implementation**: https://sepolia.etherscan.io/address/0xd25848d17d40a505ca27036a03554e12fbbd5d20
- **MockMToken**: https://sepolia.etherscan.io/address/0xb53ce3b3221d5cfcd73671a8524ec82c147515f3
- **MockSwapFacility**: https://sepolia.etherscan.io/address/0x1b68bfb49d21235b386c513a643c86e212a5dd9e
- **MockPrizeDistributor**: https://sepolia.etherscan.io/address/0x1f9b522aa93c6e57daa223770f8ee3451d5732d3

## 📊 Key Transactions

### 1. Wrap M Tokens

- **Hash**: `0x5e653824e588c97c5bbf0d152e77041307e554af0a132d79e9679fb71fc7eb10`
- **Action**: Wrapped 100,000 M tokens into extension
- **Link**: https://sepolia.etherscan.io/tx/0x5e653824e588c97c5bbf0d152e77041307e554af0a132d79e9679fb71fc7eb10

### 2. Enable Earning

- **Hash**: `0xda8d9371ac28c95c3bab88ccce015baa895c80420e1a7925576516440d069aea`
- **Action**: Started earning yield on held M tokens
- **Link**: https://sepolia.etherscan.io/tx/0xda8d9371ac28c95c3bab88ccce015baa895c80420e1a7925576516440d069aea

### 3. Claim Yield

- **Hash**: `0xb328b4cb6a61f7a43636576a405143fdd176100c3905cb6d7e80b8bd2c89b692`
- **Action**: Claimed 10,000 M tokens yield and distributed to PrizeDistributor
- **Link**: https://sepolia.etherscan.io/tx/0xb328b4cb6a61f7a43636576a405143fdd176100c3905cb6d7e80b8bd2c89b692

## 🧪 Test Results

### Initial State

- **Wrapped M Tokens**: 100,000 M
- **Total Supply**: 100,000 M
- **PrizeDistributor Balance**: 0 M

### After Yield Simulation

- **Simulated Yield**: 10,000 M tokens
- **Extension M Balance**: 110,000 M tokens
- **Total Supply**: 110,000 M tokens (100k wrapped + 10k yield)

### After Yield Claim

- **PrizeDistributor Balance**: 10,000 M tokens ✅
- **Yield Distribution**: 100% of yield successfully distributed ✅

## 🔧 Deployment Commands

```bash
# Set environment variables
export EXTENSION="0xF49149cf9C6e28CF7CE435cD0d7e3D190C9f4601"
export M_TOKEN="0xB53CE3b3221d5CFcD73671A8524EC82c147515f3"
export SWAP_FACILITY="0x1b68BFb49d21235b386c513a643C86e212A5DD9E"
export PRIZE_DISTRIBUTOR="0x1F9B522Aa93C6E57daA223770F8eE3451D5732D3"

# Test the deployment
cast send $SWAP_FACILITY 'wrapMToken(address,uint256)' \
  $EXTENSION 100000000000 \
  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

cast send $EXTENSION 'enableEarning()' \
  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

cast send $M_TOKEN 'simulateYield(address,uint256)' \
  $EXTENSION 10000000000 \
  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

cast send $EXTENSION 'claimYield()' \
  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL
```

## ✅ Verification Status

All contracts have been successfully verified on Etherscan:

- ✅ MYieldToPrizeDistributor (Proxy)
- ✅ Implementation Contract
- ✅ MockMToken
- ✅ MockSwapFacility
- ✅ MockPrizeDistributor

## 🎯 Architecture Verification

The deployed contract successfully implements the M0 MYieldToOne pattern:

1. **✅ Wrapping**: Users can wrap M tokens 1:1 into extension tokens
2. **✅ Earning**: Extension can start/stop earning on held M tokens
3. **✅ Yield Calculation**: Yield = M balance - total supply
4. **✅ Yield Distribution**: 100% of yield minted to designated recipient
5. **✅ Access Control**: Proper role-based permissions
6. **✅ Upgradeability**: UUPS proxy pattern implemented
7. **✅ Pausability**: Contract can be paused/unpaused

## 🚨 Important Notes

- This is a **testnet deployment** using mock contracts
- For mainnet deployment, replace mocks with real M0 contracts
- The extension follows M0's official architecture patterns
- All yield is automatically distributed to the PrizeDistributor
- Contract is fully upgradeable and pausable
