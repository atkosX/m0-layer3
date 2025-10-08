# MYieldToOne Extension for TestUSD on M0

A minimal, correct M0 Earner extension that holds $M (TestUSD) and routes 100% of accrued yield to a single yieldBeneficiary (PrizeDistributor).

---

## 📋 **Table of Contents**

- [Overview](#overview)
- [Architecture Decisions](#architecture-decisions)
- [Setup](#setup)
- [Usage](#usage)
- [Contract Functions](#contract-functions)
- [Testing](#testing)
- [Deployment](#deployment)
- [License](#license)

---

## Overview

MYieldToOne is an upgradeable, pausable smart contract that integrates with M0's yield earning system. It uses a **pull-based claiming model** where the contract must actively call M0 to claim accrued yield, then distributes 100% of that yield to a designated beneficiary.

### Key Features

- ✅ **Pull-based yield claiming** from M0
- ✅ **100% yield distribution** to a single beneficiary
- ✅ **Upgradeable** using UUPS proxy pattern
- ✅ **Pausable** distribution functionality
- ✅ **Role-based access control** (Admin, Gov, Pauser)
- ✅ **Reentrancy protection** on distribution

---

## Architecture Decisions

### M0 Integration Choice: Pull-Based Claiming

We chose a **pull-based claiming model** for the following reasons:

1. **Simplicity**: The contract explicitly controls when to claim yield, making the flow predictable
2. **Gas Efficiency**: Only claims when needed, avoiding unnecessary transactions
3. **Flexibility**: Can implement custom logic around claiming timing and conditions
4. **Transparency**: Clear separation between yield accrual (M0) and distribution (this contract)

### Interface Design

The contract implements minimal interfaces:

- `IMTokenLike` - M0 token interface for balance and transfer operations
- `ISwapFacility` - M0 swap facility for wrapping/unwrapping M tokens
- `IPrizeDistributor` - PrizeDistributor interface for yield distribution callbacks

### M0 Functions Integrated

**Exact M0 functions integrated:**

- `IMTokenLike.balanceOf(address)` - Check M token balance for yield calculation
- `ISwapFacility.wrap(uint256)` - Wrap M tokens to start earning
- `ISwapFacility.unwrap(uint256)` - Unwrap M tokens to stop earning
- `IPrizeDistributor.distributeYield(uint256,uint256)` - Distribute claimed yield

**Claim Model:** Pull-based - contract actively calls M0 to claim accrued yield, then distributes 100% to beneficiary.

### Proxy Pattern: UUPS

We use **UUPS (Universal Upgradeable Proxy Standard)** because:

- More gas efficient than Transparent proxies
- Upgrade logic is in the implementation contract
- Simpler admin management
- Industry standard for upgradeable contracts

---

## Setup

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Node.js (for OpenZeppelin contracts)

### Installation

```bash
# Clone and setup
git clone <your-repo>
cd m0extension-main
forge install

# Build contracts
forge build

# Run tests
forge test
```

---

## Usage

### Local Demo

Run the demo script to see the contract in action:

```bash
forge script script/Demo.s.sol
```

This will:

1. Deploy mock contracts (M0, TestUSD, PrizeDistributor)
2. Initialize MYieldToOne
3. Wrap 100k M tokens
4. Enable earning
5. Simulate 10k M yield
6. Distribute yield to beneficiary
7. Print before/after balances

**Demo Output:**

```
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

### Testnet Deployment

See [DEPLOY.md](./DEPLOY.md) for complete testnet deployment guide.

Quick start:

```bash
# 1. Set environment variables
export PRIVATE_KEY="0xYourPrivateKey"
export SEPOLIA_RPC_URL="https://your-rpc-url"

# 2. Deploy
forge script script/DeployWithMocks.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast

# 3. Use one-liners to test
cast send $PROXY 'enableEarning()' --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL
cast send $PROXY 'claimYield()' --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL
```

---

## Contract Functions

### Core Functions

| Function                                                                             | Access             | Description                                      |
| ------------------------------------------------------------------------------------ | ------------------ | ------------------------------------------------ |
| `initialize(name, symbol, mToken, swapFacility, yieldRecipient, admin, pauser, gov)` | Initializer        | Initialize the proxy                             |
| `enableEarning()`                                                                    | GOV_ROLE           | Begin earning yield via M0                       |
| `disableEarning()`                                                                   | DEFAULT_ADMIN_ROLE | Stop earning yield                               |
| `claimYield()`                                                                       | Public             | Claim and distribute all yield (when not paused) |
| `setYieldRecipient(address)`                                                         | GOV_ROLE           | Change beneficiary                               |

### Admin Functions

| Function                | Access             | Description                |
| ----------------------- | ------------------ | -------------------------- |
| `pause()` / `unpause()` | PAUSER_ROLE        | Pause/unpause distribution |
| `upgradeTo(address)`    | DEFAULT_ADMIN_ROLE | Upgrade implementation     |

### View Functions

| Function              | Returns | Description                     |
| --------------------- | ------- | ------------------------------- |
| `yield()`             | uint256 | Get claimable yield amount      |
| `totalYieldClaimed()` | uint256 | Total yield distributed to date |
| `lastClaimTime()`     | uint256 | Timestamp of last distribution  |

### Roles

- **DEFAULT_ADMIN_ROLE**: Can upgrade the contract and stop earning
- **GOV_ROLE**: Can start earning and change beneficiary
- **PAUSER_ROLE**: Can pause/unpause distribution

---

## Testing

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test testClaimYieldAfterWrapping

# Run with detailed output
forge test -vvvv
```

**Test Results:**

```
╭-------------------------------------+--------+--------+---------╮
| Test Suite                          | Passed | Failed | Skipped |
+=================================================================+
| MYieldToPrizeDistributorTest        | 53     | 0      | 0       |
|-------------------------------------+--------+--------+---------|
| MYieldToPrizeDistributorUpgradeTest | 5      | 0      | 0       |
╰-------------------------------------+--------+--------+---------╯

Total: 58 tests - 100% PASSING ✅
```

**Test Coverage:**

- ✅ Happy path: start earning, mock accrual, distribute to beneficiary
- ✅ Rotate beneficiary and distribute again
- ✅ Pause blocks distribution
- ✅ V1 to V2 upgrade path

---

## Deployment

### Live Testnet Deployment

**Network**: Sepolia Testnet  
**Block**: 9368919

**Contract Addresses:**

- **Proxy**: `0x55F20C2b576Edb53B85D1e98898b53D63C8b88D2`
- **Implementation**: `0xEFC0411F5F5Cb91A75F3ca0d2e6870da8B504484`

**Transaction Hashes:**

- **Deployment**: [`0x870d2067...`](https://sepolia.etherscan.io/tx/0x870d206707b3556633ee663097cdd7d685f9afc50bb8e3cf9b8ef23c81f5f8d3)
- **enableEarning**: [`0x3e8402b3...`](https://sepolia.etherscan.io/tx/0x3e8402b36bf1b7ef46e89325e231a93094ab0907b1f2a7d2149052f0af42075f)
- **claimYield**: [`0xc7099609...`](https://sepolia.etherscan.io/tx/0xc7099609a34e6e51da697c11465a4e7379f6c9703be927aa8906fd3bda90c08f)

**View on Etherscan:**  
https://sepolia.etherscan.io/address/0x55F20C2b576Edb53B85D1e98898b53D63C8b88D2

For complete deployment guide, see [DEPLOY.md](./DEPLOY.md)

---

## Safety Features

- **ReentrancyGuard**: Prevents reentrancy attacks on distribution
- **Pausable**: Can pause distribution in emergencies
- **Access Control**: Role-based permissions for all admin functions
- **Yield Validation**: Ensures yield exists before distribution


---

## Project Structure

```
m0extension-main/
├── src/
│   ├── MYieldToPrizeDistributor.sol    # Main contract (V1)
│   └── MYieldToPrizeDistributorV2.sol  # Upgrade demonstration (V2)
├── interfaces/
│   ├── IMTokenLike.sol                 # M0 token interface
│   ├── ISwapFacility.sol               # Swap facility interface
│   └── IPrizeDistributor.sol           # Prize distributor interface
├── test/
│   ├── MYieldToPrizeDistributor.t.sol  # Core tests (53 tests)
│   ├── MYieldToPrizeDistributorUpgrade.t.sol # Upgrade tests (5 tests)
│   └── mocks/                          # Mock contracts
├── script/
│   ├── Demo.s.sol                      # Demo with balance tracking
│   └── DeployWithMocks.s.sol           # Full deployment
├── README.md                            # This file
└── DEPLOY.md                            # Deployment guide
```

---

## License

MIT
