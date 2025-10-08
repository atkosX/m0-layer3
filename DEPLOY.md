# Testnet Deployment Guide

Complete guide for deploying MYieldToOne Extension to testnet.

---

## 📋 **Table of Contents**

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Deployment Steps](#deployment-steps)
- [One-Liner Commands](#one-liner-commands)
- [Actual Deployment Results](#actual-deployment-results)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- ✅ Foundry installed and configured
- ✅ Testnet ETH for gas fees
- ✅ Private key for deployment

---

## Environment Setup

### Set Environment Variables

Create a `.env` file or export variables:

```bash
# Required for deployment
export PRIVATE_KEY="0xYourPrivateKey"
export SEPOLIA_RPC_URL="https://your-rpc-url"

# Optional: Etherscan API key for verification
export ETHERSCAN_API_KEY="your-etherscan-api-key"
```

### Verify Environment

```bash
# Check that variables are set
echo "RPC: $SEPOLIA_RPC_URL"
echo "Private Key: ${PRIVATE_KEY:0:10}..."
```

---

## Deployment Steps

### Step 1: Deploy Full System

```bash
forge script script/DeployWithMocks.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY
```

**This will deploy:**

- Mock M Token
- Mock SwapFacility
- Mock PrizeDistributor
- MYieldToOne Implementation
- MYieldToOne Proxy (initialized)

### Step 2: Save Contract Addresses

From the deployment output, save these addresses:

```bash
export EXTENSION="0x[ProxyAddress]"
export M_TOKEN="0x[MTokenAddress]"
export SWAP_FACILITY="0x[SwapFacilityAddress]"
export PRIZE_DISTRIBUTOR="0x[PrizeDistributorAddress]"
```

### Step 3: Verify Deployment

```bash
# Check contract is initialized
cast call $EXTENSION "name()(string)" --rpc-url $SEPOLIA_RPC_URL
cast call $EXTENSION "yieldRecipient()(address)" --rpc-url $SEPOLIA_RPC_URL
cast call $EXTENSION "earningActive()(bool)" --rpc-url $SEPOLIA_RPC_URL
```

---

## One-Liner Commands

### Start Earning

```bash
cast send $EXTENSION 'enableEarning()' \
  --private-key $PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL
```

### Claim and Distribute Yield

```bash
cast send $EXTENSION 'claimYield()' \
  --private-key $PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL
```

### Complete Test Flow

```bash
# 1. Wrap 100k M tokens
cast send $SWAP_FACILITY 'wrapMToken(address,uint256)' \
  $EXTENSION 100000000000 \
  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

# 2. Enable earning
cast send $EXTENSION 'enableEarning()' \
  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

# 3. Simulate yield (10k M)
cast send $M_TOKEN 'simulateYield(address,uint256)' \
  $EXTENSION 10000000000 \
  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

# 4. Check claimable yield
cast call $EXTENSION 'yield()(uint256)' --rpc-url $SEPOLIA_RPC_URL

# 5. Claim and distribute yield
cast send $EXTENSION 'claimYield()' \
  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

# 6. Check PrizeDistributor balance
cast call $EXTENSION 'balanceOf(address)(uint256)' \
  $PRIZE_DISTRIBUTOR --rpc-url $SEPOLIA_RPC_URL
```

---

## 🚀 **Actual Deployment Results**

### Network Information

- **Network**: Sepolia Testnet
- **Chain ID**: 11155111
- **Block Number**: 9368919
- **Deployment Date**: December 2024

### Contract Addresses

| Contract                                 | Address                                      |
| ---------------------------------------- | -------------------------------------------- |
| **MYieldToOne Proxy**                    | `0x55F20C2b576Edb53B85D1e98898b53D63C8b88D2` |
| **MYieldToOne Implementation**           | `0xEFC0411F5F5Cb91A75F3ca0d2e6870da8B504484` |
| **Admin**                                | `0xad484485127B501B63274Ed34B594C8FC3f22504` |
| **Yield Beneficiary (PrizeDistributor)** | `0xbe65531Bd68d1D5E898D6061484761dbf2221b3E` |
| **M Token (Mock)**                       | `0x2B5899D1d1607FEfBfD54D6EfD2659Cc146b20c2` |
| **SwapFacility (Mock)**                  | `0x700669F97C704A5f11F12555c9160DE23ac9bCAa` |

### Transaction Hashes

| Operation                       | Transaction Hash                                                     |
| ------------------------------- | -------------------------------------------------------------------- |
| **Contract Deployment**         | `0x870d206707b3556633ee663097cdd7d685f9afc50bb8e3cf9b8ef23c81f5f8d3` |
| **M Token Deployment**          | `0x18c3e29606fd9fa7c4a1c68fe49e0bd46fb5c77bdb080b52ee7d7a45e3a308b9` |
| **SwapFacility Deployment**     | `0x780f4dba0023a131d122b2f42390846fda4b36e85040be9fb5092f55c122935f` |
| **PrizeDistributor Deployment** | `0xf37e64749b67803bb29a7178a54acffa868a44aa5b3d84c82f0fc68885ec3bce` |
| **Wrap M Tokens**               | `0xd455319e9cef8103b6537bb38c517594c98c30fc167285e23958a8ed497cfdb0` |
| **Enable Earning**              | `0x3e8402b36bf1b7ef46e89325e231a93094ab0907b1f2a7d2149052f0af42075f` |
| **Simulate Yield**              | `0xe493a2c9202b07d9ea8b369a45d1863ee1a1f72fd52055f2971b14530bf8a4d4` |
| **Claim Yield**                 | `0xc7099609a34e6e51da697c11465a4e7379f6c9703be927aa8906fd3bda90c08f` |

### Etherscan Links

**Contract Addresses:**

- **Proxy Contract**: https://sepolia.etherscan.io/address/0x55F20C2b576Edb53B85D1e98898b53D63C8b88D2
- **Implementation Contract**: https://sepolia.etherscan.io/address/0xEFC0411F5F5Cb91A75F3ca0d2e6870da8B504484
- **M Token**: https://sepolia.etherscan.io/address/0x2B5899D1d1607FEfBfD54D6EfD2659Cc146b20c2
- **SwapFacility**: https://sepolia.etherscan.io/address/0x700669F97C704A5f11F12555c9160DE23ac9bCAa
- **PrizeDistributor**: https://sepolia.etherscan.io/address/0xbe65531Bd68d1D5E898D6061484761dbf2221b3E

**Transaction Links:**

- **enableEarning TX**: https://sepolia.etherscan.io/tx/0x3e8402b36bf1b7ef46e89325e231a93094ab0907b1f2a7d2149052f0af42075f
- **claimYield TX**: https://sepolia.etherscan.io/tx/0xc7099609a34e6e51da697c11465a4e7379f6c9703be927aa8906fd3bda90c08f

### Deployment Verification

✅ **All tests passing**: 58/58 tests (100% success rate)  
✅ **All core functionality verified**: End-to-end flow tested  
✅ **Demo script working**: Balance tracking confirmed  
✅ **Contracts deployed**: Live on Sepolia Block 9368919

### Test Results

```
========================================
    DEMO COMPLETE - SUCCESS!
========================================

=== INITIAL BALANCES ===
Extension M token balance: 100000 M
Extension total supply: 100000 tokens
PrizeDistributor balance: 0 tokens
Claimable yield: 0 M

=== BALANCES AFTER DISTRIBUTION ===
Extension M token balance: 110000 M
Extension total supply: 110000 tokens
PrizeDistributor balance: 10000 tokens
Total yield claimed: 10000 M

Distribution successful: YES
```

---

## Verification

### Contract Verification (Optional)

If you want to verify contracts on Etherscan:

```bash
forge verify-contract $IMPLEMENTATION \
  src/MYieldToPrizeDistributor.sol:MYieldToPrizeDistributor \
  --chain sepolia \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Function Verification

Test key functions to ensure proper deployment:

```bash
# Check roles
cast call $EXTENSION "hasRole(bytes32,address)" \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  $ADMIN --rpc-url $SEPOLIA_RPC_URL

# Check earning status
cast call $EXTENSION "earningActive()(bool)" --rpc-url $SEPOLIA_RPC_URL

# Check beneficiary
cast call $EXTENSION "yieldRecipient()(address)" --rpc-url $SEPOLIA_RPC_URL

# Check claimable yield
cast call $EXTENSION "yield()(uint256)" --rpc-url $SEPOLIA_RPC_URL
```
