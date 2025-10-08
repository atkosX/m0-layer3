# M0 Integration Guide - Real M0 Extension

## 🎯 Architecture Change: Standalone → Real M0 Extension

We've now properly integrated with M0's actual contracts by extending their audited `MYieldToOne` base.

---

## 📊 Before vs After

### ❌ Previous Approach (Standalone)
```solidity
// Custom implementation from scratch
contract MYieldToOne is
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable {
    
    IM0 public m0;  // Mock interface
    
    function startEarning() {
        m0.startEarning(address(this), balance);
    }
    
    function claimYield() {
        uint256 yield = m0.claimYield();
        // Transfer yield
    }
}
```

**Problems**:
- ❌ Not using M0's audited contracts
- ❌ Custom wrap/unwrap logic
- ❌ Mock interfaces instead of real M0
- ❌ Would need M0 governance approval
- ❌ Higher audit costs

### ✅ New Approach (Real M0 Extension)
```solidity
// Extends M0's audited base
import { MYieldToOne } from "m0-extensions/MYieldToOne.sol";

contract MYieldToPrizeDistributor is MYieldToOne {
    constructor(address mToken, address swapFacility)
        MYieldToOne(mToken, swapFacility) {}
        
    // Inherits all M0 functionality
    // Just adds Prize Distributor integration
}
```

**Benefits**:
- ✅ Uses M0's audited and battle-tested code
- ✅ Automatic wrap/unwrap via SwapFacility
- ✅ Real M0 protocol integration
- ✅ Easier governance approval
- ✅ Lower audit surface

---

## 🏗️ Real M0 Architecture

### How It Actually Works

```
┌─────────────┐
│    Users    │
└──────┬──────┘
       │ 1. Deposit M via SwapFacility
       ├──────────────────────────────────┐
       │                                  │
       v                                  v
┌──────────────────┐              ┌─────────────┐
│  SwapFacility    │──wrap()─────>│ MYieldTo... │
│  (M0 Contract)   │              │  Extension  │
└──────────────────┘              └──────┬──────┘
                                         │
                                         │ M tokens held here
                                         │ Earning yield from M0
                                         │
                                         v
                                  ┌────────────────┐
                                  │ Yield Accrues  │
                                  │ (M bal - supply)│
                                  └───────┬────────┘
                                          │
                                          v
                                   claimYield()
                                          │
                                          v
                              ┌───────────────────────┐
                              │  Mints extension      │
                              │  tokens to            │
                              │  PrizeDistributor     │
                              └───────────┬───────────┘
                                          │
                                          v
                              ┌───────────────────────┐
                              │  PrizeDistributor     │
                              │  unwraps → gets M     │
                              │  distributes prizes   │
                              └───────────────────────┘
```

### Key Concepts

1. **Wrapping**: Users deposit M tokens via SwapFacility → receive extension tokens
2. **Earning**: The contract's M tokens earn yield in the M protocol
3. **Yield Calculation**: `yield = mToken.balanceOf(extension) - extension.totalSupply()`
4. **Claiming**: Anyone calls `claimYield()` → mints extension tokens to yieldRecipient
5. **Unwrapping**: yieldRecipient unwraps extension tokens → gets M tokens back

---

## 📁 New File Structure

```
m0extension/
├── contracts/                    # M0's actual contracts (from m-extensions)
│   ├── MExtension.sol           # Base: wrap/unwrap/earning logic
│   ├── projects/
│   │   └── yieldToOne/
│   │       └── MYieldToOne.sol  # Base: yield to single recipient
│   └── components/
│       └── Freezable.sol        # Freeze functionality
│
├── src/
│   ├── MYieldToPrizeDistributor.sol  # OUR extension (extends M0's base)
│   └── MYieldToOne.sol              # OLD standalone (deprecated)
│
├── interfaces/
│   ├── IM0.sol                     # OLD mock interface (deprecated)
│   └── IPrizeDistributor.sol       # Our PrizeDistributor interface
│
└── test/
    └── MYieldToPrizeDistributor.t.sol  # NEW tests for real integration
```

---

## 🔧 Contract Comparison

### M0's MYieldToOne (Base)
```solidity
// Located in: contracts/projects/yieldToOne/MYieldToOne.sol

contract MYieldToOne is MExtension, Freezable {
    // ✅ Already has wrap/unwrap (from MExtension)
    // ✅ Already has earning enable/disable
    // ✅ Already has freeze functionality
    // ✅ Already has yield calculation
    // ✅ Already has yield claiming
    // ✅ Already has yield recipient management
    
    function claimYield() public returns (uint256) {
        uint256 yield_ = yield();  // M balance - total supply
        _mint(yieldRecipient(), yield_);  // Mint extension tokens
        return yield_;
    }
    
    function setYieldRecipient(address account) external {
        claimYield();  // Claim for old recipient first
        _setYieldRecipient(account);
    }
}
```

### Our MYieldToPrizeDistributor (Extension)
```solidity
// Located in: src/MYieldToPrizeDistributor.sol

contract MYieldToPrizeDistributor is MYieldToOne {
    // ✅ Inherits ALL functionality from M0's MYieldToOne
    // ✅ Only adds PrizeDistributor-specific integration
    
    function claimAndDistributeYield() external returns (uint256) {
        uint256 yieldAmount = claimYield();  // Call parent
        
        // Add our custom logic: notify PrizeDistributor
        IPrizeDistributor(yieldRecipient()).distributeYield(
            yieldAmount,
            block.timestamp
        );
        
        return yieldAmount;
    }
    
    // That's it! Everything else is inherited.
}
```

---

## 🚀 Deployment with Real M0

### Step 1: Get M0 Contract Addresses

For testnets/mainnet, you need:
```bash
# Sepolia or mainnet addresses
M_TOKEN=0x...              # M0's M token address
SWAP_FACILITY=0x...        # M0's SwapFacility address
PRIZE_DISTRIBUTOR=0x...    # Your PrizeDistributor address
```

### Step 2: Deploy Implementation
```solidity
// Deploy with M0's actual addresses
MYieldToPrizeDistributor implementation = new MYieldToPrizeDistributor(
    M_TOKEN,           // Real M token
    SWAP_FACILITY      // Real SwapFacility
);
```

### Step 3: Deploy Proxy and Initialize
```solidity
bytes memory initData = abi.encodeWithSelector(
    MYieldToPrizeDistributor.initialize.selector,
    "M Yield to PrizeDistributor",  // name
    "MYPD",                          // symbol  
    PRIZE_DISTRIBUTOR,               // yieldRecipient
    msg.sender,                      // admin
    msg.sender,                      // freezeManager
    msg.sender                       // yieldRecipientManager
);

ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
```

### Step 4: Enable Earning
```solidity
MYieldToPrizeDistributor extension = MYieldToPrizeDistributor(address(proxy));

// Enable earning for the extension
extension.enableEarning();
```

### Step 5: Users Wrap M Tokens
```solidity
// Users approve and wrap via SwapFacility
IERC20(M_TOKEN).approve(SWAP_FACILITY, amount);
ISwapFacility(SWAP_FACILITY).wrapMToken(address(extension), amount);

// User receives extension tokens
```

### Step 6: Claim Yield
```solidity
// Anyone can call this
extension.claimAndDistributeYield();

// This:
// 1. Calculates yield (M balance - total supply)
// 2. Mints extension tokens to PrizeDistributor
// 3. Notifies PrizeDistributor with yield amount
```

---

## 🔑 Key Functions

### From M0's MExtension (Inherited)

| Function | Description | Who Can Call |
|----------|-------------|--------------|
| `wrap()` | Wrap M → extension tokens | SwapFacility only |
| `unwrap()` | Unwrap extension → M | SwapFacility only |
| `enableEarning()` | Start earning M yield | Anyone (first time) |
| `disableEarning()` | Stop earning M yield | Anyone (if enabled) |
| `isEarningEnabled()` | Check earning status | Anyone (view) |

### From M0's MYieldToOne (Inherited)

| Function | Description | Who Can Call |
|----------|-------------|--------------|
| `claimYield()` | Claim yield, mint to recipient | Anyone |
| `setYieldRecipient()` | Change yield recipient | YIELD_RECIPIENT_MANAGER |
| `yield()` | View current claimable yield | Anyone (view) |
| `yieldRecipient()` | View current recipient | Anyone (view) |

### From Our Extension (New)

| Function | Description | Who Can Call |
|----------|-------------|--------------|
| `claimAndDistributeYield()` | Claim yield + notify PrizeDistributor | Anyone |
| `prizeDistributor()` | View PrizeDistributor address | Anyone (view) |

---

## 🧪 Testing with Real M0

### For Local Testing:
```bash
# 1. Clone M0 contracts (already done in contracts/)
# 2. Deploy mock M token and SwapFacility for tests
# 3. Deploy your extension
# 4. Test wrap → earn → claim → unwrap flow
```

### For Testnet:
```bash
# Use M0's actual testnet deployments
# Find addresses in M0's documentation or ask M0 team
```

---

## 🎯 Migration Path

### What Changes for Users

**Before (Standalone)**:
1. Admin manually calls `startEarning()`
2. Admin calls `pullAndDistributeYield()`
3. Yield transferred directly

**After (Real M0)**:
1. Users wrap M via SwapFacility → get extension tokens
2. Anyone calls `enableEarning()` once
3. Anyone calls `claimAndDistributeYield()`
4. PrizeDistributor receives extension tokens
5. PrizeDistributor unwraps to get M for prizes

### What Changes for Developers

**Before**:
```solidity
// Custom implementation
extension.startEarning();
extension.pullAndDistributeYield();
```

**After**:
```solidity
// Real M0 integration
extension.enableEarning();  // Once
extension.claimAndDistributeYield();  // Periodically
```

---

## 📚 Additional Resources

- **M0 Documentation**: https://docs.m0.org
- **M0 Extensions Repo**: https://github.com/m0-foundation/m-extensions
- **M0 Discord**: https://discord.gg/m0
- **SwapFacility Guide**: [M0 Docs - SwapFacility]

---

## ✅ Benefits of Real Integration

1. **Security**: Uses M0's audited contracts
2. **Compatibility**: Works with M0 ecosystem out of the box
3. **Maintenance**: M0 team maintains base contracts
4. **Trust**: M0 governance already approved base
5. **Simplicity**: Less code to audit and maintain
6. **Ecosystem**: Compatible with other M0 tools

---

## 🚧 Next Steps

1. ✅ Contracts copied from m-extensions
2. ✅ MYieldToPrizeDistributor created
3. ⏳ Update tests for real M0 integration
4. ⏳ Update demo script for wrap/unwrap flow
5. ⏳ Deploy to testnet with real M0 addresses
6. ⏳ Verify with M0 team
7. ⏳ Get governance approval if needed

---

**This is the CORRECT way to integrate with M0!** 🎉

