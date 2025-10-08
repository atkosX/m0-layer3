# 🎯 M0 MYieldToOne Extension

A minimal, correct M0 Earner extension that holds $M and routes 100% of accrued yield to a single `yieldBeneficiary` (PrizeDistributor).

## 🏗️ Architecture & Design Choices

### **Interface Choices**

This implementation follows M0's **MYieldToOne** pattern with the following key design decisions:

1. **Direct OpenZeppelin Inheritance**: Instead of inheriting from M0's base contracts (`MExtension`, `Freezable`), this implementation directly inherits from OpenZeppelin's upgradeable contracts for simplicity and full control.

2. **Pull-Based Yield Distribution**: The contract uses a "pull" model where anyone can call `claimYield()` to distribute accrued yield to the beneficiary. This is more gas-efficient than automatic distribution.

3. **ERC1967 Proxy Pattern**: Uses OpenZeppelin's UUPS (Universal Upgradeable Proxy Standard) for upgradeability, allowing future improvements without migration.

4. **Role-Based Access Control**: Implements three distinct roles:
   - `DEFAULT_ADMIN_ROLE`: Can pause/unpause and manage other roles
   - `YIELD_RECIPIENT_MANAGER_ROLE`: Can change the yield beneficiary
   - `FREEZE_MANAGER_ROLE`: Can freeze/unfreeze accounts

### **M0 Integration Points**

- **Earning Management**: Integrates with M0's `startEarning()` and `stopEarning()` functions
- **Yield Calculation**: Uses M0's pattern: `yield = M_balance - totalSupply`
- **SwapFacility Integration**: Properly handles wrap/unwrap through M0's SwapFacility
- **Yield Distribution**: Mints extension tokens to beneficiary (100% of yield)

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js (for testing)
- Sepolia ETH (for testnet deployment)

### Installation

```bash
git clone <your-repo>
cd m0extension-main
forge install
```

### Local Testing

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test test_ClaimYield
```

### Testnet Deployment

```bash
# 1. Set up environment
cp .env.template .env
# Edit .env with your private key and RPC URL

# 2. Deploy to Sepolia
./deploy.sh

# 3. Test the deployment
# Follow commands in DEPLOY.md
```

## 📋 Contract Functions

### Core Functions

- `initialize()`: Initialize the contract with M token, swap facility, and beneficiary
- `wrap()`: Wrap M tokens into extension tokens (called by SwapFacility)
- `unwrap()`: Unwrap extension tokens back to M (called by SwapFacility)
- `enableEarning()`: Start earning yield on held M tokens
- `disableEarning()`: Stop earning yield
- `claimYield()`: Distribute all accrued yield to beneficiary
- `setYieldRecipient()`: Change the yield beneficiary

### View Functions

- `yield()`: Get current claimable yield amount
- `isEarningEnabled()`: Check if earning is active
- `mBalance()`: Get current M token balance
- `balanceOf()`: Get extension token balance
- `totalSupply()`: Get total supply of extension tokens

### Admin Functions

- `pause()` / `unpause()`: Pause/unpause the contract
- `freeze()` / `unfreeze()`: Freeze/unfreeze specific accounts
- `setYieldRecipient()`: Change yield beneficiary

## 🧪 Testing

### Test Coverage

- ✅ Happy path: wrap → enable earning → simulate yield → claim yield
- ✅ Role-based access control
- ✅ Pause functionality
- ✅ Freeze functionality
- ✅ Yield calculation accuracy
- ✅ Beneficiary rotation
- ✅ Reentrancy protection

### Running Tests

```bash
# All tests
forge test

# Specific test suite
forge test --match-contract MYieldToPrizeDistributorTest

# Gas optimization
forge test --gas-report
```

## 🔒 Security Features

1. **Reentrancy Protection**: All state-changing functions protected with `nonReentrant`
2. **Access Control**: Role-based permissions for all admin functions
3. **Pausability**: Contract can be paused in emergency situations
4. **Freezing**: Individual accounts can be frozen for compliance
5. **Input Validation**: All inputs validated (zero address, zero amount checks)
6. **Upgrade Safety**: Only admin can authorize upgrades

## 📊 Gas Optimization

- **Efficient Storage**: Minimal state variables, packed structs where possible
- **Batch Operations**: Support for batch freezing/unfreezing
- **Event Optimization**: Only essential events emitted
- **Function Optimization**: Inline small functions, avoid unnecessary external calls

## 🚨 Risk Assessment

### Low Risk

- ✅ Standard OpenZeppelin patterns
- ✅ Comprehensive test coverage
- ✅ Clear access control
- ✅ Upgradeable design

### Medium Risk

- ⚠️ Centralized yield recipient (by design)
- ⚠️ Admin key management (use multisig)
- ⚠️ Upgrade authorization (admin only)

### Mitigation Strategies

- Use multisig for admin roles
- Implement timelock for critical functions
- Regular security audits
- Monitor for unusual activity

## 📈 Yield Distribution Model

```
User wraps 100 M tokens
    ↓
Extension holds 100 M tokens
    ↓
M tokens earn yield (e.g., 5 M tokens)
    ↓
Extension balance: 105 M tokens
Extension totalSupply: 100 tokens
    ↓
Claimable yield: 5 M tokens
    ↓
claimYield() mints 5 extension tokens to PrizeDistributor
    ↓
PrizeDistributor can unwrap to get 5 M tokens
```

## 🔧 Development

### Project Structure

```
src/
├── MYieldToPrizeDistributor.sol    # Main contract
interfaces/
├── IMTokenLike.sol                 # M token interface
├── ISwapFacility.sol              # Swap facility interface
└── IPrizeDistributor.sol          # Prize distributor interface
test/
├── MYieldToPrizeDistributor.t.sol # Main test suite
└── mocks/                         # Mock contracts
script/
└── DeployWithMocks.s.sol         # Deployment script
```

### Adding Features

1. Write tests first
2. Implement feature
3. Update documentation
4. Run full test suite
5. Deploy to testnet

## 📝 License

MIT License - see LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Write tests
4. Submit pull request

## 📞 Support

For questions or issues:

- Create GitHub issue
- Check testnet deployment in DEPLOY.md
- Review test cases for usage examples
