// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MYieldToPrizeDistributor} from "../src/MYieldToPrizeDistributor.sol";
import {MockMToken} from "./mocks/MockMToken.sol";
import {MockSwapFacility} from "./mocks/MockSwapFacility.sol";
import {MockPrizeDistributor} from "./mocks/MockPrizeDistributor.sol";

/**
 * @title MYieldToPrizeDistributor Test Suite
 * @notice Comprehensive tests for M0 extension following real M0 architecture
 */
contract MYieldToPrizeDistributorTest is Test {
    MYieldToPrizeDistributor public extension;
    MockMToken public mToken;
    MockSwapFacility public swapFacility;
    MockPrizeDistributor public prizeDistributor;

    address public admin = address(0x1);
    address public pauser = address(0x1); // Same as admin for testing
    address public gov = address(0x3);
    address public user1 = address(0x100);
    address public user2 = address(0x200);

    uint256 constant INITIAL_M_BALANCE = 1_000_000e6; // 1M M tokens
    uint256 constant WRAP_AMOUNT = 100_000e6; // 100k M tokens

    event Transfer(address indexed from, address indexed to, uint256 value);
    event YieldClaimed(uint256 amount, address indexed recipient);
    event EarningEnabled(uint256 indexed atIndex);
    event EarningDisabled(uint256 indexed atIndex);
    event Wrapped(address indexed account, uint256 amount);
    event Unwrapped(address indexed account, uint256 amount);

    function setUp() public {
        // Deploy mocks
        mToken = new MockMToken();
        swapFacility = new MockSwapFacility(address(mToken));
        prizeDistributor = new MockPrizeDistributor();

        // Deploy extension implementation
        MYieldToPrizeDistributor implementation = new MYieldToPrizeDistributor();

        // Deploy proxy and initialize
        bytes memory initData = abi.encodeWithSelector(
            MYieldToPrizeDistributor.initialize.selector,
            "M Yield to PrizeDistributor",
            "MYPD",
            address(mToken),
            address(swapFacility),
            address(prizeDistributor),
            admin,
            pauser,
            gov
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        extension = MYieldToPrizeDistributor(address(proxy));

        // Mint M tokens to users
        mToken.mint(user1, INITIAL_M_BALANCE);
        mToken.mint(user2, INITIAL_M_BALANCE);

        // Approve swap facility
        vm.prank(user1);
        mToken.approve(address(swapFacility), type(uint256).max);

        vm.prank(user2);
        mToken.approve(address(swapFacility), type(uint256).max);
    }

    /* ============ Initialization Tests ============ */

    function test_Initialization() public view {
        assertEq(extension.name(), "M Yield to PrizeDistributor");
        assertEq(extension.symbol(), "MYPD");
        assertEq(address(extension.mToken()), address(mToken));
        assertEq(address(extension.swapFacility()), address(swapFacility));
        assertEq(extension.yieldRecipient(), address(prizeDistributor));
        assertFalse(extension.earningActive());
        assertEq(extension.totalSupply(), 0);
    }

    function test_InitializationRoles() public view {
        assertTrue(extension.hasRole(extension.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(extension.hasRole(extension.PAUSER_ROLE(), pauser));
        assertTrue(extension.hasRole(extension.GOV_ROLE(), gov));
    }

    function test_CannotReinitialize() public {
        vm.expectRevert();
        extension.initialize(
            "Test",
            "TST",
            address(mToken),
            address(swapFacility),
            address(prizeDistributor),
            admin,
            pauser,
            gov
        );
    }

    /* ============ Wrap/Unwrap Tests ============ */

    function test_WrapTokens() public {
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        assertEq(extension.balanceOf(user1), WRAP_AMOUNT);
        assertEq(extension.totalSupply(), WRAP_AMOUNT);
        assertEq(mToken.balanceOf(address(extension)), WRAP_AMOUNT);
    }

    function test_WrapEmitsTransferEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), user1, WRAP_AMOUNT);

        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);
    }

    function test_UnwrapTokens() public {
        // First wrap
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        uint256 unwrapAmount = 50_000e6;

        // Then unwrap
        vm.prank(user1);
        swapFacility.unwrapMToken(address(extension), unwrapAmount);

        assertEq(extension.balanceOf(user1), WRAP_AMOUNT - unwrapAmount);
        assertEq(extension.totalSupply(), WRAP_AMOUNT - unwrapAmount);
    }

    function test_WrapRevertsIfNotSwapFacility() public {
        vm.expectRevert(MYieldToPrizeDistributor.NotSwapFacility.selector);
        extension.wrap(user1, WRAP_AMOUNT);
    }

    function test_UnwrapRevertsIfNotSwapFacility() public {
        vm.expectRevert(MYieldToPrizeDistributor.NotSwapFacility.selector);
        extension.unwrap(user1, WRAP_AMOUNT);
    }

    /* ============ Earning Tests ============ */

    function test_EnableEarning() public {
        vm.expectEmit(true, false, false, false);
        emit EarningEnabled(mToken.currentIndex());

        extension.enableEarning();

        assertTrue(extension.earningActive());
        assertTrue(mToken.isEarning(address(extension)));
    }

    function test_DisableEarning() public {
        extension.enableEarning();

        vm.expectEmit(true, false, false, false);
        emit EarningDisabled(mToken.currentIndex());

        extension.disableEarning();

        assertFalse(extension.earningActive());
        assertFalse(mToken.isEarning(address(extension)));
    }

    function test_EnableEarningRevertsIfAlreadyEnabled() public {
        extension.enableEarning();

        vm.expectRevert(MYieldToPrizeDistributor.EarningAlreadyEnabled.selector);
        extension.enableEarning();
    }

    function test_DisableEarningRevertsIfNotEnabled() public {
        vm.expectRevert(MYieldToPrizeDistributor.EarningNotEnabled.selector);
        extension.disableEarning();
    }

    function test_EnableDisableEarningCycle() public {
        extension.enableEarning();
        assertTrue(extension.earningActive());

        extension.disableEarning();
        assertFalse(extension.earningActive());

        extension.enableEarning();
        assertTrue(extension.earningActive());
    }

    /* ============ Yield Claiming Tests ============ */

    function test_ClaimYieldWithNoYield() public {
        uint256 yielded = extension.claimYield();
        assertEq(yielded, 0);
    }

    function test_ClaimYieldAfterWrapping() public {
        // User wraps M tokens
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        // Enable earning
        extension.enableEarning();

        // Simulate yield accrual (M balance increases)
        uint256 yieldAmount = 10_000e6; // 10k M yield
        mToken.simulateYield(address(extension), yieldAmount);

        // Check yield is calculated correctly
        assertEq(extension.yield(), yieldAmount);

        // Claim yield
        vm.expectEmit(true, true, false, true);
        emit YieldClaimed(yieldAmount, address(prizeDistributor));

        uint256 claimed = extension.claimYield();

        assertEq(claimed, yieldAmount);
        assertEq(extension.balanceOf(address(prizeDistributor)), yieldAmount);
        assertEq(prizeDistributor.totalReceived(), yieldAmount);
    }

    function test_ClaimYieldUpdatesSupply() public {
        // Wrap tokens
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        // Simulate yield
        uint256 yieldAmount = 5_000e6;
        mToken.simulateYield(address(extension), yieldAmount);

        uint256 supplyBefore = extension.totalSupply();

        // Claim yield
        extension.claimYield();

        // Total supply should increase by yield amount
        assertEq(extension.totalSupply(), supplyBefore + yieldAmount);
    }

    function test_MultipleYieldClaims() public {
        // Wrap tokens
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        extension.enableEarning();

        // First yield
        uint256 yield1 = 5_000e6;
        mToken.simulateYield(address(extension), yield1);
        extension.claimYield();

        // Second yield
        uint256 yield2 = 3_000e6;
        mToken.simulateYield(address(extension), yield2);
        extension.claimYield();

        assertEq(prizeDistributor.totalReceived(), yield1 + yield2);
        assertEq(extension.balanceOf(address(prizeDistributor)), yield1 + yield2);
    }

    function test_YieldCalculation() public view {
        // No tokens wrapped yet
        assertEq(extension.yield(), 0);
    }

    function test_YieldCalculationWithWrappedTokens() public {
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        // M balance = totalSupply, so yield = 0
        assertEq(extension.yield(), 0);

        // Simulate yield
        uint256 yieldAmount = 7_500e6;
        mToken.simulateYield(address(extension), yieldAmount);

        // Now yield should equal the simulated amount
        assertEq(extension.yield(), yieldAmount);
    }

    function test_MBalance() public {
        assertEq(extension.mBalance(), 0);

        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        assertEq(extension.mBalance(), WRAP_AMOUNT);
    }

    /* ============ Yield Recipient Management Tests ============ */

    function test_SetYieldRecipient() public {
        address newRecipient = address(0x999);

        vm.prank(gov);
        extension.setYieldRecipient(newRecipient);

        assertEq(extension.yieldRecipient(), newRecipient);
    }

    function test_SetYieldRecipientClaimsPendingYield() public {
        // Wrap and generate yield
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        uint256 yieldAmount = 5_000e6;
        mToken.simulateYield(address(extension), yieldAmount);

        // Change yield recipient (should claim existing yield first)
        address newRecipient = address(0x999);

        vm.prank(gov);
        extension.setYieldRecipient(newRecipient);

        // Old recipient should have received the yield
        assertEq(extension.balanceOf(address(prizeDistributor)), yieldAmount);
        assertEq(prizeDistributor.totalReceived(), yieldAmount);

        // New recipient is now set
        assertEq(extension.yieldRecipient(), newRecipient);
    }

    function test_SetYieldRecipientRevertsIfNotAuthorized() public {
        vm.expectRevert();
        extension.setYieldRecipient(address(0x999));
    }

    function test_SetYieldRecipientRevertsIfZeroAddress() public {
        vm.prank(gov);
        vm.expectRevert(MYieldToPrizeDistributor.ZeroAddress.selector);
        extension.setYieldRecipient(address(0));
    }

    /* ============ ERC20 Transfer Tests ============ */

    function test_Transfer() public {
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        uint256 transferAmount = 10_000e6;

        vm.prank(user1);
        extension.transfer(user2, transferAmount);

        assertEq(extension.balanceOf(user1), WRAP_AMOUNT - transferAmount);
        assertEq(extension.balanceOf(user2), transferAmount);
    }

    function test_TransferEmitsEvent() public {
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        uint256 transferAmount = 10_000e6;

        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, user2, transferAmount);

        vm.prank(user1);
        extension.transfer(user2, transferAmount);
    }

    function test_TransferRevertsIfInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert(MYieldToPrizeDistributor.InsufficientBalance.selector);
        extension.transfer(user2, WRAP_AMOUNT);
    }

    function test_Approve() public {
        uint256 approvalAmount = 50_000e6;

        vm.prank(user1);
        extension.approve(user2, approvalAmount);

        assertEq(extension.allowance(user1, user2), approvalAmount);
    }

    function test_TransferFrom() public {
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        uint256 transferAmount = 10_000e6;

        vm.prank(user1);
        extension.approve(user2, transferAmount);

        vm.prank(user2);
        extension.transferFrom(user1, user2, transferAmount);

        assertEq(extension.balanceOf(user2), transferAmount);
        assertEq(extension.allowance(user1, user2), 0);
    }

    function test_TransferFromRevertsIfInsufficientAllowance() public {
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        vm.prank(user2);
        vm.expectRevert(MYieldToPrizeDistributor.InsufficientAllowance.selector);
        extension.transferFrom(user1, user2, WRAP_AMOUNT);
    }

    /* ============ Freeze Tests ============ */

    function test_FreezeAccount() public {
        vm.prank(pauser);
        extension.freeze(user1);

        assertTrue(extension.frozen(user1));
    }

    function test_UnfreezeAccount() public {
        vm.prank(pauser);
        extension.freeze(user1);

        vm.prank(pauser);
        extension.unfreeze(user1);

        assertFalse(extension.frozen(user1));
    }

    function test_FrozenAccountCannotTransfer() public {
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        vm.prank(pauser);
        extension.freeze(user1);

        vm.prank(user1);
        vm.expectRevert();
        extension.transfer(user2, 1000e6);
    }

    function test_CannotTransferToFrozenAccount() public {
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        vm.prank(pauser);
        extension.freeze(user2);

        vm.prank(user1);
        vm.expectRevert();
        extension.transfer(user2, 1000e6);
    }

    function test_FreezeRevertsIfNotAuthorized() public {
        vm.expectRevert();
        extension.freeze(user1);
    }

    /* ============ Pause Tests ============ */

    function test_Pause() public {
        vm.prank(admin);
        extension.pause();

        assertTrue(extension.paused());
    }

    function test_Unpause() public {
        vm.prank(admin);
        extension.pause();

        vm.prank(admin);
        extension.unpause();

        assertFalse(extension.paused());
    }

    function test_ClaimYieldRevertsWhenPaused() public {
        vm.prank(admin);
        extension.pause();

        vm.expectRevert();
        extension.claimYield();
    }

    function test_EnableEarningRevertsWhenPaused() public {
        vm.prank(admin);
        extension.pause();

        vm.expectRevert();
        extension.enableEarning();
    }

    function test_PauseRevertsIfNotAdmin() public {
        vm.expectRevert();
        extension.pause();
    }

    function test_UnpauseRevertsIfNotPauser() public {
        // First pause with admin
        vm.prank(admin);
        extension.pause();
        
        // Try to unpause without PAUSER_ROLE
        vm.expectRevert();
        extension.unpause();
    }

    function test_SetYieldRecipientRevertsIfNotGov() public {
        // Try with PAUSER_ROLE (should fail)
        vm.prank(pauser);
        vm.expectRevert();
        extension.setYieldRecipient(address(0x999));
    }

    function test_FreezeRevertsIfNotAdmin() public {
        // Try with GOV_ROLE (should fail)
        vm.prank(gov);
        vm.expectRevert();
        extension.freeze(user1);
    }

    function test_UnfreezeRevertsIfNotAdmin() public {
        // First freeze with admin
        vm.prank(admin);
        extension.freeze(user1);
        
        // Try to unfreeze without DEFAULT_ADMIN_ROLE
        vm.prank(gov);
        vm.expectRevert();
        extension.unfreeze(user1);
    }

    /* ============ Integration Tests ============ */

    function test_CompleteFlow() public {
        console.log("=== Starting Complete Flow Test ===");

        // 1. User wraps M tokens
        console.log("Step 1: User wraps", WRAP_AMOUNT / 1e6, "M tokens");
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        assertEq(extension.balanceOf(user1), WRAP_AMOUNT);
        assertEq(extension.totalSupply(), WRAP_AMOUNT);

        // 2. Enable earning
        console.log("Step 2: Enable earning");
        extension.enableEarning();
        assertTrue(extension.earningActive());

        // 3. Simulate yield accrual
        uint256 yieldAmount = 15_000e6;
        console.log("Step 3: Simulate", yieldAmount / 1e6, "M yield");
        mToken.simulateYield(address(extension), yieldAmount);

        assertEq(extension.yield(), yieldAmount);

        // 4. Claim yield
        console.log("Step 4: Claim yield");
        uint256 claimed = extension.claimYield();

        assertEq(claimed, yieldAmount);
        assertEq(extension.balanceOf(address(prizeDistributor)), yieldAmount);
        assertEq(prizeDistributor.totalReceived(), yieldAmount);

        // 5. User transfers some tokens
        console.log("Step 5: User transfers tokens");
        uint256 transferAmount = 20_000e6;
        vm.prank(user1);
        extension.transfer(user2, transferAmount);

        assertEq(extension.balanceOf(user2), transferAmount);

        // 6. Generate more yield and claim again
        console.log("Step 6: Generate and claim more yield");
        uint256 yield2 = 8_000e6;
        mToken.simulateYield(address(extension), yield2);
        extension.claimYield();

        assertEq(prizeDistributor.totalReceived(), yieldAmount + yield2);

        console.log("=== Complete Flow Test Successful ===");
    }

    function test_MultiUserScenario() public {
        // User 1 wraps
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        // User 2 wraps
        vm.prank(user2);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT / 2);

        assertEq(extension.totalSupply(), WRAP_AMOUNT + WRAP_AMOUNT / 2);

        // Enable earning
        extension.enableEarning();

        // Simulate yield
        uint256 yieldAmount = 20_000e6;
        mToken.simulateYield(address(extension), yieldAmount);

        // Claim yield
        extension.claimYield();

        // Yield goes to PrizeDistributor
        assertEq(extension.balanceOf(address(prizeDistributor)), yieldAmount);

        // Users can still trade their tokens
        vm.prank(user1);
        extension.transfer(user2, 10_000e6);

        assertEq(extension.balanceOf(user1), WRAP_AMOUNT - 10_000e6);
        assertEq(extension.balanceOf(user2), WRAP_AMOUNT / 2 + 10_000e6);
    }

    /* ============ Edge Case Tests ============ */

    function test_ClaimYieldWithZeroYield() public view {
        uint256 yielded = extension.yield();
        assertEq(yielded, 0);
    }

    function test_TransferZeroAmount() public {
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        vm.prank(user1);
        bool success = extension.transfer(user2, 0);

        assertTrue(success);
        assertEq(extension.balanceOf(user2), 0);
    }

    function test_ApproveMaxAmount() public {
        vm.prank(user1);
        extension.approve(user2, type(uint256).max);

        assertEq(extension.allowance(user1, user2), type(uint256).max);
    }

    function test_UnwrapPartialAmount() public {
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);

        vm.prank(user1);
        swapFacility.unwrapMToken(address(extension), WRAP_AMOUNT / 4);

        assertEq(extension.balanceOf(user1), WRAP_AMOUNT - WRAP_AMOUNT / 4);
    }

    /* ============ Stretch Goal Tests ============ */

    function test_CumulativeYieldTracking() public {
        // Initial state
        assertEq(extension.totalYieldClaimed(), 0);
        assertEq(extension.lastClaimTime(), 0);

        // Wrap and generate yield
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);
        extension.enableEarning();

        uint256 yield1 = 5_000e6;
        mToken.simulateYield(address(extension), yield1);
        extension.claimYield();

        // Check tracking
        assertEq(extension.totalYieldClaimed(), yield1);
        assertEq(extension.lastClaimTime(), block.timestamp);

        // Generate more yield
        uint256 yield2 = 3_000e6;
        mToken.simulateYield(address(extension), yield2);
        extension.claimYield();

        // Check cumulative tracking
        assertEq(extension.totalYieldClaimed(), yield1 + yield2);
        assertEq(extension.lastClaimTime(), block.timestamp);
    }

    function test_EpochTrackingInPrizeDistributor() public {
        // Wrap and generate yield
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);
        extension.enableEarning();

        uint256 yield1 = 5_000e6;
        mToken.simulateYield(address(extension), yield1);
        extension.claimYield();

        // Check epoch tracking
        assertEq(prizeDistributor.getEpochCount(), 1);
        assertEq(prizeDistributor.getLastEpoch(), block.timestamp);
        assertEq(prizeDistributor.epochYield(block.timestamp), yield1);

        // Generate more yield
        uint256 yield2 = 3_000e6;
        mToken.simulateYield(address(extension), yield2);
        extension.claimYield();

        // Check multiple epochs
        assertEq(prizeDistributor.getEpochCount(), 2);
        assertEq(prizeDistributor.getTotalYieldReceived(), yield1 + yield2);
    }

    function test_PrizeDistributorEpochHelpers() public {
        // Generate some yield
        vm.prank(user1);
        swapFacility.wrapMToken(address(extension), WRAP_AMOUNT);
        extension.enableEarning();

        uint256 yield1 = 5_000e6;
        mToken.simulateYield(address(extension), yield1);
        extension.claimYield();

        // Test epoch helpers
        assertEq(prizeDistributor.getEpochCount(), 1);
        assertEq(prizeDistributor.getLastEpoch(), block.timestamp);

        // Test epoch yield at index
        (uint256 epoch, uint256 yield) = prizeDistributor.getEpochYieldAt(0);
        assertEq(epoch, block.timestamp);
        assertEq(yield, yield1);
    }
}


