# 🔐 Multi-Role Deployment Guide

## 🎯 **Deployment Options**

### **Option 1: Single Key (Current - Testing)**

```bash
# All roles go to deployer address
./deploy.sh
```

**Environment Setup:**

```bash
# .env file
PRIVATE_KEY=0xYOUR_PRIVATE_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
```

**Result:**

- Deployer gets: `DEFAULT_ADMIN_ROLE`, `PAUSER_ROLE`, `GOV_ROLE`
- Simple and fast for testing

### **Option 2: Multi-Role (Production)**

**Environment Setup:**

```bash
# .env file
ADMIN_PRIVATE_KEY=0xYOUR_ADMIN_PRIVATE_KEY
ADMIN_ADDRESS=0xYOUR_ADMIN_ADDRESS
PAUSER_ADDRESS=0xYOUR_PAUSER_ADDRESS
GOV_ADDRESS=0xYOUR_GOV_ADDRESS
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
```

**Deploy:**

```bash
forge script script/DeployMultiRole.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

## 🔄 **Role Management After Deployment**

### **Transfer Roles to Different Addresses:**

```bash
# Transfer PAUSER_ROLE to new address
cast send $EXTENSION 'grantRole(bytes32,address)' \
  $(cast keccak256 "PAUSER_ROLE") \
  0xNEW_PAUSER_ADDRESS \
  --private-key $ADMIN_PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

# Transfer GOV_ROLE to new address
cast send $EXTENSION 'grantRole(bytes32,address)' \
  $(cast keccak256 "GOV_ROLE") \
  0xNEW_GOV_ADDRESS \
  --private-key $ADMIN_PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL
```

### **Revoke Roles:**

```bash
# Revoke PAUSER_ROLE from old address
cast send $EXTENSION 'revokeRole(bytes32,address)' \
  $(cast keccak256 "PAUSER_ROLE") \
  0xOLD_PAUSER_ADDRESS \
  --private-key $ADMIN_PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL
```

## 🏗️ **Production Best Practices**

### **Role Assignment Strategy:**

- **DEFAULT_ADMIN_ROLE**: Multisig contract (3-5 signers)
- **PAUSER_ROLE**: Emergency multisig (2-3 signers)
- **GOV_ROLE**: Governance contract or multisig

### **Security Considerations:**

1. **Never use same key for all roles in production**
2. **Use multisig contracts for critical roles**
3. **Keep admin key secure and separate**
4. **Test role transfers on testnet first**

## 🧪 **Testing Role Separation**

```bash
# Test that pauser can pause but not change yield recipient
cast send $EXTENSION 'pause()' \
  --private-key $PAUSER_PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

# This should fail (pauser can't change yield recipient)
cast send $EXTENSION 'setYieldRecipient(address)' \
  0xNEW_RECIPIENT \
  --private-key $PAUSER_PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL
```

## 📋 **Quick Start (Single Key)**

For your assignment submission, **single key deployment is perfect**:

```bash
# 1. Set up environment
cp .env.template .env
# Edit .env with your private key and RPC URL

# 2. Deploy
./deploy.sh

# 3. Test
forge test

# 4. Verify on Etherscan
# Check that all roles are assigned to deployer address
```

**This gives you everything you need for the assignment!** 🎉
