# MYieldToOne Audit Fixes Checklist

## Critical Fixes (Must Complete)

### 1. Add Missing Functions ❌

**File**: `src/MYieldToOne.sol`

- [ ] Add `startEarning()` function
  ```solidity
  function startEarning() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
      require(!earningActive, "MYieldToOne: already earning");
      require(address(m0) != address(0), "MYieldToOne: M0 not set");
      
      uint256 balance = IERC20(m0.mToken()).balanceOf(address(this));
      require(balance > 0, "MYieldToOne: no M tokens");
      
      m0.startEarning(address(this), balance);
      earningActive = true;
      
      emit EarningStarted(balance);
  }
  ```

- [ ] Add `stopEarning()` function
  ```solidity
  function stopEarning() external onlyRole(DEFAULT_ADMIN_ROLE) {
      require(earningActive, "MYieldToOne: not earning");
      require(address(m0) != address(0), "MYieldToOne: M0 not set");
      
      uint256 balance = m0.balanceOf(address(this));
      if (balance > 0) {
          m0.stopEarning(address(this), balance);
      }
      earningActive = false;
      
      emit EarningStopped(balance);
  }
  ```

- [ ] Add missing events
  ```solidity
  event EarningStarted(uint256 amount);
  event EarningStopped(uint256 amount);
  ```

- [ ] Add tests for `startEarning()` in `test/MYieldToOne.t.sol`:
  - [ ] `test_StartEarning()`
  - [ ] `test_StartEarning_RevertWhenAlreadyEarning()`
  - [ ] `test_StartEarning_RevertWhenPaused()`
  - [ ] `test_StartEarning_RevertWhenNoTokens()`
  
- [ ] Add tests for `stopEarning()`:
  - [ ] `test_StopEarning()`
  - [ ] `test_StopEarning_RevertWhenNotEarning()`
  - [ ] `test_StopEarning_RevertWhenNotAuthorized()`

### 2. Add Missing State Variable ❌

**File**: `src/MYieldToOne.sol`

- [ ] Add `earningActive` state variable:
  ```solidity
  bool public earningActive;
  ```

- [ ] Update initialization to set it to false:
  ```solidity
  earningActive = false;
  ```

### 3. Fix Role Names ❌

**File**: `src/MYieldToOne.sol`

- [ ] Rename `FREEZE_MANAGER_ROLE` to `PAUSER_ROLE` or remove freeze functionality
- [ ] Rename `YIELD_RECIPIENT_MANAGER_ROLE` to `GOV_ROLE`
- [ ] Update all references throughout the contract
- [ ] Update all references in tests

**Search and Replace**:
```bash
FREEZE_MANAGER_ROLE -> PAUSER_ROLE
YIELD_RECIPIENT_MANAGER_ROLE -> GOV_ROLE
freezeManager -> pauser (in variable names)
yieldRecipientManager -> governor (in variable names)
```

### 4. Fix Function Names ❌

**File**: `src/MYieldToOne.sol`

- [ ] Rename `claimYield()` to `pullAndDistributeYield()`
- [ ] Rename `setYieldRecipient()` to `setYieldBeneficiary()`
- [ ] Update all references in tests
- [ ] Update all references in scripts
- [ ] Update all references in documentation

**Search and Replace**:
```bash
claimYield -> pullAndDistributeYield
setYieldRecipient -> setYieldBeneficiary
yieldRecipient -> yieldBeneficiary (variable name)
getYieldRecipient -> getYieldBeneficiary
YieldRecipientChanged -> YieldBeneficiaryChanged
```

### 5. Fix Initialization Signature ❌

**File**: `src/MYieldToOne.sol`

Current (6 parameters):
```solidity
function initialize(
    string memory name_,
    string memory symbol_,
    address treasury_,
    address admin_,
    address freezeManager_,
    address yieldRecipientManager_
) external initializer
```

Change to (3 parameters per spec):
```solidity
function initialize(
    address m_,
    address yieldBeneficiary_,
    address admin_
) external initializer {
    require(m_ != address(0), "MYieldToOne: invalid M");
    require(yieldBeneficiary_ != address(0), "MYieldToOne: invalid beneficiary");
    require(admin_ != address(0), "MYieldToOne: invalid admin");
    
    __UUPSUpgradeable_init();
    __AccessControl_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    
    m0 = IM0(m_);
    yieldBeneficiary = yieldBeneficiary_;
    earningActive = false;
    
    // Grant all three roles to admin initially
    _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    _grantRole(GOV_ROLE, admin_);
    _grantRole(PAUSER_ROLE, admin_);
}
```

- [ ] Update function signature
- [ ] Remove `name` and `symbol` state variables (not in spec)
- [ ] Remove `setM0()` function (M set in initialize now)
- [ ] Update ALL test calls to `initialize()`
- [ ] Update deploy script
- [ ] Update demo script

### 6. Enable Constructor Initializer Guard ❌

**File**: `src/MYieldToOne.sol`

- [ ] Uncomment `_disableInitializers()`:
  ```solidity
  constructor() {
      _disableInitializers();
  }
  ```

### 7. Remove Extra Complexity (Optional but Recommended) ⚠️

**File**: `src/MYieldToOne.sol`

- [ ] Remove `freeze()` function (use pause instead)
- [ ] Remove `unfreeze()` function (use unpause instead)
- [ ] Remove `frozen` state variable
- [ ] Remove related tests for freeze/unfreeze
- [ ] Update `claimYield` to only check `whenNotPaused`, not frozen
- [ ] Remove `Frozen` and `Unfrozen` events

---

## Medium Priority Fixes

### 8. Fix Demo Script ⚠️

**File**: `script/Demo.s.sol`

- [ ] Replace `address(this)` with `vm.addr(1)` or similar
- [ ] Update to use new 3-parameter `initialize()`
- [ ] Test that demo runs successfully

### 9. Update Tests ⚠️

**File**: `test/MYieldToOne.t.sol`

- [ ] Update all `initialize()` calls to 3-parameter version
- [ ] Remove `setM0()` calls (now in initialize)
- [ ] Update function names in all tests
- [ ] Update role names in all tests
- [ ] Ensure all tests still pass after changes

### 10. Complete Testnet Deployment ⚠️

**File**: `DEPLOY.md`

- [ ] Choose testnet (e.g., Base Sepolia)
- [ ] Set up environment variables
- [ ] Deploy to testnet
- [ ] Document contract address
- [ ] Call `startEarning()` and document tx hash
- [ ] Wait for yield / mock yield
- [ ] Call `pullAndDistributeYield()` and document tx hash
- [ ] Update DEPLOY.md with actual artifacts

---

## Documentation Updates

### 11. Update README ℹ️

**File**: `README.md`

- [ ] Add concise 5-10 line summary at top explaining choices
- [ ] Update function names in examples
- [ ] Update role names in documentation
- [ ] Verify all code examples match implementation

### 12. Update DEPLOY.md ℹ️

**File**: `DEPLOY.md`

- [ ] Update with actual testnet deployment results
- [ ] Add network name
- [ ] Add contract addresses
- [ ] Add transaction links
- [ ] Add verification links

---

## Testing Checklist

### Before Submission

- [ ] Run `forge build` - compiles without errors
- [ ] Run `forge test` - all tests pass
- [ ] Run `forge test -vvv` - check detailed traces
- [ ] Run demo script successfully
- [ ] Verify all spec requirements met (see AUDIT_REPORT.md)

### Test Coverage

- [ ] Happy path: start earning → accrue → distribute
- [ ] Beneficiary rotation
- [ ] Pause blocks distribution
- [ ] Start/stop earning
- [ ] Role-based access control
- [ ] Edge cases and errors

---

## Final Verification Checklist

### Spec Compliance

- [ ] Roles: DEFAULT_ADMIN_ROLE ✓
- [ ] Roles: GOV_ROLE ✓
- [ ] Roles: PAUSER_ROLE ✓
- [ ] State: address M ✓
- [ ] State: address yieldBeneficiary ✓
- [ ] State: bool earningActive ✓
- [ ] Function: `initialize(M, yieldBeneficiary, admin)` ✓
- [ ] Function: `startEarning()` ✓
- [ ] Function: `stopEarning()` ✓
- [ ] Function: `pullAndDistributeYield()` ✓
- [ ] Function: `setYieldBeneficiary(address)` ✓
- [ ] Function: `pause()` / `unpause()` ✓
- [ ] Events: all required events present ✓
- [ ] Reentrancy guard on distribution ✓
- [ ] No way to divert yield ✓

### Deliverables

- [ ] MYieldToOne.sol with all required functions
- [ ] Minimal interfaces (IM0, IPrizeDistributor)
- [ ] Simple mocks
- [ ] Tests covering happy path
- [ ] Tests covering rotation
- [ ] Tests covering pause
- [ ] Demo script that runs
- [ ] Deploy script
- [ ] README with 5-10 line explanation
- [ ] DEPLOY.md with testnet artifacts
- [ ] Testnet deployment completed

---

## Estimated Time to Complete

- **Critical Fixes (1-7)**: 4-6 hours
- **Medium Fixes (8-10)**: 2-3 hours
- **Documentation (11-12)**: 1-2 hours
- **Testing & Verification**: 2-3 hours

**Total**: ~10-14 hours

---

## Need Help?

### Common Issues

**Q: How do I batch rename across files?**
```bash
# Example: rename claimYield to pullAndDistributeYield
find . -type f \( -name "*.sol" -o -name "*.md" \) -exec sed -i '' 's/claimYield/pullAndDistributeYield/g' {} +
```

**Q: Tests failing after changes?**
- Check all `initialize()` calls updated to 3 params
- Check all role names updated
- Check all function names updated

**Q: How to verify I've fixed everything?**
- Use this checklist
- Compare against AUDIT_REPORT.md
- Ensure forge test passes
- Ensure demo script runs

---

## Next Steps After Fixes

1. ✅ Complete all items in this checklist
2. ✅ Run full test suite
3. ✅ Complete testnet deployment
4. ✅ Update documentation
5. ✅ Submit for final review

---

*Last Updated*: October 7, 2025

