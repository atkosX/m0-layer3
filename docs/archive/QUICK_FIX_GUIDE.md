# Quick Fix Guide - MYieldToOne

**Priority**: Fix these issues to meet specification requirements

---

## 🔴 CRITICAL: Add Missing Functions (30 minutes)

### Step 1: Add State Variable

**File**: `src/MYieldToOne.sol` (line 34, after `totalYieldDistributed`)

```solidity
bool public earningActive;
```

### Step 2: Add Events

**File**: `src/MYieldToOne.sol` (line 44, after existing events)

```solidity
event EarningStarted(uint256 amount);
event EarningStopped(uint256 amount);
```

### Step 3: Add startEarning() Function

**File**: `src/MYieldToOne.sol` (after `claimYield()`, around line 126)

```solidity
/**
 * @notice Start earning yield from M0
 * @dev Calls M0's startEarning hook with current M token balance
 */
function startEarning() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
    require(!frozen, "MYieldToOne: frozen");
    require(address(m0) != address(0), "MYieldToOne: M0 not set");
    require(!earningActive, "MYieldToOne: already earning");
    
    uint256 balance = IERC20(m0.mToken()).balanceOf(address(this));
    require(balance > 0, "MYieldToOne: no M tokens to earn with");
    
    m0.startEarning(address(this), balance);
    earningActive = true;
    
    emit EarningStarted(balance);
}
```

### Step 4: Add stopEarning() Function

**File**: `src/MYieldToOne.sol` (after `startEarning()`)

```solidity
/**
 * @notice Stop earning yield from M0
 * @dev Calls M0's stopEarning hook
 */
function stopEarning() external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(address(m0) != address(0), "MYieldToOne: M0 not set");
    require(earningActive, "MYieldToOne: not earning");
    
    uint256 balance = m0.balanceOf(address(this));
    if (balance > 0) {
        m0.stopEarning(address(this), balance);
    }
    earningActive = false;
    
    emit EarningStopped(balance);
}
```

### Step 5: Initialize earningActive

**File**: `src/MYieldToOne.sol` (in `initialize()`, around line 89)

Add after role grants:
```solidity
earningActive = false;
```

---

## 🔴 CRITICAL: Rename Functions (15 minutes)

### Automated Rename Commands

```bash
cd /Users/aviralshukla/Developer/FunSideProjects/m0extension

# Rename claimYield to pullAndDistributeYield
find . -type f \( -name "*.sol" -o -name "*.md" \) -not -path "./lib/*" -not -path "./out/*" \
  -exec sed -i '' 's/claimYield/pullAndDistributeYield/g' {} +

# Rename setYieldRecipient to setYieldBeneficiary
find . -type f \( -name "*.sol" -o -name "*.md" \) -not -path "./lib/*" -not -path "./out/*" \
  -exec sed -i '' 's/setYieldRecipient/setYieldBeneficiary/g' {} +

# Rename yieldRecipient to yieldBeneficiary
find . -type f \( -name "*.sol" -o -name "*.md" \) -not -path "./lib/*" -not -path "./out/*" \
  -exec sed -i '' 's/yieldRecipient/yieldBeneficiary/g' {} +

# Rename getYieldRecipient to getYieldBeneficiary
find . -type f \( -name "*.sol" -o -name "*.md" \) -not -path "./lib/*" -not -path "./out/*" \
  -exec sed -i '' 's/getYieldRecipient/getYieldBeneficiary/g' {} +

# Rename event
find . -type f \( -name "*.sol" \) -not -path "./lib/*" -not -path "./out/*" \
  -exec sed -i '' 's/YieldRecipientChanged/YieldBeneficiaryChanged/g' {} +
```

---

## 🔴 CRITICAL: Rename Roles (15 minutes)

### Automated Rename Commands

```bash
cd /Users/aviralshukla/Developer/FunSideProjects/m0extension

# Rename YIELD_RECIPIENT_MANAGER_ROLE to GOV_ROLE
find . -type f \( -name "*.sol" -o -name "*.md" \) -not -path "./lib/*" -not -path "./out/*" \
  -exec sed -i '' 's/YIELD_RECIPIENT_MANAGER_ROLE/GOV_ROLE/g' {} +

# Rename yieldRecipientManager to governor (parameter names)
find . -type f \( -name "*.sol" \) -not -path "./lib/*" -not -path "./out/*" \
  -exec sed -i '' 's/yieldRecipientManager/governor/g' {} +

# Rename FREEZE_MANAGER_ROLE to PAUSER_ROLE
find . -type f \( -name "*.sol" -o -name "*.md" \) -not -path "./lib/*" -not -path "./out/*" \
  -exec sed -i '' 's/FREEZE_MANAGER_ROLE/PAUSER_ROLE/g' {} +

# Rename freezeManager to pauser (parameter names)
find . -type f \( -name "*.sol" \) -not -path "./lib/*" -not -path "./out/*" \
  -exec sed -i '' 's/freezeManager/pauser/g' {} +
```

---

## 🔴 CRITICAL: Fix Initialization (45 minutes)

### Step 1: Update Function Signature

**File**: `src/MYieldToOne.sol` (around line 61)

**Current**:
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

**Change to**:
```solidity
function initialize(
    address m_,
    address yieldBeneficiary_,
    address admin_
) external initializer
```

### Step 2: Update Function Body

**Replace lines 61-90 with**:

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

    // Grant all roles to admin
    _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    _grantRole(GOV_ROLE, admin_);
    _grantRole(PAUSER_ROLE, admin_);
}
```

### Step 3: Remove setM0() Function

**File**: `src/MYieldToOne.sol` (lines 93-101)

**DELETE** the entire `setM0()` function.

### Step 4: Remove name and symbol State Variables

**File**: `src/MYieldToOne.sol` (lines 36-38)

**DELETE**:
```solidity
string public name;
string public symbol;
```

---

## 🔴 CRITICAL: Enable Constructor Guard (2 minutes)

**File**: `src/MYieldToOne.sol` (lines 47-50)

**Current**:
```solidity
constructor() {
    // Temporarily comment out for testing - should call parent constructor
    // _disableInitializers();
}
```

**Change to**:
```solidity
constructor() {
    _disableInitializers();
}
```

---

## 🔴 CRITICAL: Update All Tests (60 minutes)

### Update initialize() Calls

**File**: `test/MYieldToOne.t.sol`

**Find all instances of**:
```solidity
extension.initialize(
    "MYieldToOne",
    "MYT1",
    treasury,
    address(this),
    freezeManager,
    yieldRecipientManager
);
```

**Replace with**:
```solidity
extension.initialize(
    address(mockM0),
    treasury,
    address(this)
);
```

**Also remove all `setM0()` calls** since M0 is now set in initialize.

### Add New Tests

**File**: `test/MYieldToOne.t.sol` (after existing tests)

```solidity
function test_StartEarning() public {
    assertFalse(extension.earningActive());
    
    vm.prank(address(this));
    extension.startEarning();
    
    assertTrue(extension.earningActive());
    assertTrue(mockM0.isEarning(address(extension)));
}

function test_StartEarning_RevertWhenAlreadyEarning() public {
    vm.prank(address(this));
    extension.startEarning();
    
    vm.prank(address(this));
    vm.expectRevert("MYieldToOne: already earning");
    extension.startEarning();
}

function test_StopEarning() public {
    vm.prank(address(this));
    extension.startEarning();
    assertTrue(extension.earningActive());
    
    vm.prank(address(this));
    extension.stopEarning();
    assertFalse(extension.earningActive());
}

function test_StopEarning_RevertWhenNotEarning() public {
    vm.prank(address(this));
    vm.expectRevert("MYieldToOne: not earning");
    extension.stopEarning();
}

function test_StartEarning_RevertWhenNotAuthorized() public {
    vm.prank(user);
    vm.expectRevert();
    extension.startEarning();
}
```

---

## 🟡 MEDIUM: Fix Demo Script (20 minutes)

**File**: `script/Demo.s.sol`

### Change 1: Replace address(this)

**Line 27**: Change from:
```solidity
address admin = address(this);
```

To:
```solidity
address admin = msg.sender;
```

### Change 2: Update initialize() Call

**Lines 37-44**: Change from:
```solidity
extension.initialize(
    "MYieldToOne",
    "MYT1",
    address(prizeDistributor),
    admin,
    admin,
    admin
);
```

To:
```solidity
extension.initialize(
    address(mockM0),
    address(prizeDistributor),
    admin
);
```

### Change 3: Remove setM0() Call

**Delete lines 46-48** (the setM0 call and prank).

### Change 4: Add startEarning() Call

**After funding extension (around line 53), add**:

```solidity
console2.log("\n4. Starting earning...");
vm.prank(admin);
extension.startEarning();
console2.log("   Earning active:", extension.earningActive());
```

### Change 5: Update function names

**Replace**:
- `claimYield()` → `pullAndDistributeYield()`
- `setYieldRecipient()` → `setYieldBeneficiary()`

---

## 🟡 MEDIUM: Update Deploy Script (10 minutes)

**File**: `script/Deploy.s.sol`

### Update initialize() Call

**Lines 36-43**: Change to:

```solidity
implementation.initialize(
    m0Address,
    yieldBeneficiary,
    admin
);
```

### Remove setM0() Call

**Delete lines 46-49** (the setM0 prank block).

---

## Verification Commands

After all fixes, run these commands:

```bash
# Compile
forge build

# Run tests
forge test -vv

# Run demo
forge script script/Demo.s.sol -vv

# Check for compilation errors
forge build --force
```

---

## Expected Results

✅ All tests should pass  
✅ Demo script should run successfully  
✅ No compilation errors  
✅ All spec requirements met  

---

## Time Estimate

- Add missing functions: 30 min
- Rename functions: 15 min
- Rename roles: 15 min
- Fix initialization: 45 min
- Enable constructor guard: 2 min
- Update tests: 60 min
- Fix demo script: 20 min
- Update deploy script: 10 min
- Verification: 20 min

**Total**: ~3.5 hours

---

## After Fixes Checklist

- [ ] `forge build` succeeds
- [ ] `forge test` all pass
- [ ] Demo script runs
- [ ] All function names match spec
- [ ] All role names match spec
- [ ] Initialize signature matches spec (3 params)
- [ ] Constructor guard enabled
- [ ] startEarning/stopEarning present
- [ ] earningActive state variable present
- [ ] All events present

---

## Need More Help?

See detailed documents:
- `AUDIT_REPORT.md` - Full audit findings
- `AUDIT_FIXES_CHECKLIST.md` - Detailed checklist
- `SPEC_VS_IMPLEMENTATION.md` - Side-by-side comparison

---

**Quick Reference: Spec Required Functions**

```solidity
// Must have these exact signatures:
function initialize(address M, address yieldBeneficiary, address admin) external;
function startEarning() external;
function stopEarning() external;
function pullAndDistributeYield() external;
function setYieldBeneficiary(address) external;
function pause() external;
function unpause() external;
```

**Quick Reference: Spec Required Roles**

```solidity
bytes32 public constant DEFAULT_ADMIN_ROLE; // OpenZeppelin default
bytes32 public constant GOV_ROLE = keccak256("GOV_ROLE");
bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
```

**Quick Reference: Spec Required State**

```solidity
IM0 public m0;  // or: address public M;
address public yieldBeneficiary;
bool public earningActive;
```

---

*Last Updated: October 7, 2025*

