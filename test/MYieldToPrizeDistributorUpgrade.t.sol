// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MYieldToPrizeDistributor} from "../src/MYieldToPrizeDistributor.sol";
import {MYieldToPrizeDistributorV2} from "../src/MYieldToPrizeDistributorV2.sol";
import {MockMToken} from "./mocks/MockMToken.sol";
import {MockSwapFacility} from "./mocks/MockSwapFacility.sol";
import {MockPrizeDistributor} from "./mocks/MockPrizeDistributor.sol";

/**
 * @title MYieldToPrizeDistributor Upgrade Test
 * @notice Tests UUPS upgradeability from V1 to V2
 * @dev Demonstrates upgrade pattern with additional V2 features
 */
contract MYieldToPrizeDistributorUpgradeTest is Test {
    MYieldToPrizeDistributor public v1;
    MYieldToPrizeDistributorV2 public v2;
    MockMToken public mToken;
    MockSwapFacility public swapFacility;
    MockPrizeDistributor public prizeDistributor;

    address public admin = address(0x1);
    address public pauser = address(0x1);
    address public gov = address(0x3);
    address public user1 = address(0x100);

    uint256 constant WRAP_AMOUNT = 100_000e6;
    uint256 constant YIELD_AMOUNT = 10_000e6;

    function setUp() public {
        // Deploy mocks
        mToken = new MockMToken();
        swapFacility = new MockSwapFacility(address(mToken));
        prizeDistributor = new MockPrizeDistributor();

        // Deploy V1 implementation
        MYieldToPrizeDistributor v1Implementation = new MYieldToPrizeDistributor();

        // Deploy V1 proxy
        bytes memory initData = abi.encodeWithSelector(
            MYieldToPrizeDistributor.initialize.selector,
            "M Yield to PrizeDistributor V1",
            "MYPDV1",
            address(mToken),
            address(swapFacility),
            address(prizeDistributor),
            admin,
            pauser,
            gov
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(v1Implementation), initData);
        v1 = MYieldToPrizeDistributor(address(proxy));

        // Mint tokens to user
        mToken.mint(user1, 1_000_000e6);
        vm.prank(user1);
        mToken.approve(address(swapFacility), type(uint256).max);
    }

    function test_UpgradeFromV1ToV2() public {
        console.log("=== Testing V1 to V2 Upgrade ===");

        // 1. Test V1 functionality
        console.log("Step 1: Testing V1 functionality");
        
        // Wrap tokens
        vm.prank(user1);
        swapFacility.wrapMToken(address(v1), WRAP_AMOUNT);
        assertEq(v1.balanceOf(user1), WRAP_AMOUNT);

        // Enable earning and generate yield
        v1.enableEarning();
        mToken.simulateYield(address(v1), YIELD_AMOUNT);
        
        // Claim yield in V1
        uint256 claimedV1 = v1.claimYield();
        assertEq(claimedV1, YIELD_AMOUNT);
        assertEq(v1.totalYieldClaimed(), YIELD_AMOUNT);
        assertEq(v1.lastClaimTime(), block.timestamp);

        // 2. Deploy V2 implementation
        console.log("Step 2: Deploying V2 implementation");
        MYieldToPrizeDistributorV2 v2Implementation = new MYieldToPrizeDistributorV2();

        // 3. Upgrade proxy to V2
        console.log("Step 3: Upgrading proxy to V2");
        vm.prank(admin);
        v1.upgradeToAndCall(address(v2Implementation), "");

        // Cast to V2 interface
        v2 = MYieldToPrizeDistributorV2(address(v1));

        // 4. Verify V2 state is preserved
        console.log("Step 4: Verifying V2 state preservation");
        assertEq(v2.name(), "M Yield to PrizeDistributor V1"); // Name preserved
        assertEq(v2.symbol(), "MYPDV1"); // Symbol preserved
        assertEq(v2.totalYieldClaimed(), YIELD_AMOUNT); // V1 data preserved
        assertEq(v2.lastClaimTime(), block.timestamp); // V1 data preserved
        assertEq(v2.balanceOf(user1), WRAP_AMOUNT); // User balance preserved
        assertEq(v2.totalSupply(), WRAP_AMOUNT + YIELD_AMOUNT); // Supply preserved

        // 5. Test V2 specific features
        console.log("Step 5: Testing V2 specific features");
        assertEq(v2.VERSION(), 2);
        assertEq(v2.yieldClaimCount(), 0); // V2 tracking starts fresh
        assertEq(v2.averageYieldPerClaim(), 0);

        // 6. Generate more yield and test V2 functionality
        console.log("Step 6: Testing V2 yield claiming");
        uint256 yield2 = 5_000e6;
        mToken.simulateYield(address(v2), yield2);
        
        uint256 claimedV2 = v2.claimYield();
        assertEq(claimedV2, yield2);
        assertEq(v2.totalYieldClaimed(), YIELD_AMOUNT + yield2);
        assertEq(v2.yieldClaimCount(), 1);
        assertEq(v2.averageYieldPerClaim(), YIELD_AMOUNT + yield2);

        // 7. Test V2 statistics function
        console.log("Step 7: Testing V2 statistics");
        (uint256 claimCount, uint256 totalClaimed, uint256 averagePerClaim, uint256 lastClaim) = 
            v2.getYieldStatistics();
        
        assertEq(claimCount, 1);
        assertEq(totalClaimed, YIELD_AMOUNT + yield2);
        assertEq(averagePerClaim, YIELD_AMOUNT + yield2);
        assertEq(lastClaim, block.timestamp);

        console.log("=== V1 to V2 Upgrade Test Successful ===");
    }

    function test_UpgradePreservesAllState() public {
        // Set up some state in V1
        vm.prank(user1);
        swapFacility.wrapMToken(address(v1), WRAP_AMOUNT);
        
        v1.enableEarning();
        mToken.simulateYield(address(v1), YIELD_AMOUNT);
        v1.claimYield();

        // Upgrade to V2
        MYieldToPrizeDistributorV2 v2Implementation = new MYieldToPrizeDistributorV2();
        vm.prank(admin);
        v1.upgradeToAndCall(address(v2Implementation), "");
        v2 = MYieldToPrizeDistributorV2(address(v1));

        // Verify all state is preserved
        assertEq(v2.balanceOf(user1), WRAP_AMOUNT);
        assertEq(v2.totalSupply(), WRAP_AMOUNT + YIELD_AMOUNT);
        assertEq(v2.totalYieldClaimed(), YIELD_AMOUNT);
        assertEq(v2.earningActive(), true);
        assertEq(v2.yieldRecipient(), address(prizeDistributor));
        assertTrue(v2.hasRole(v2.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(v2.hasRole(v2.PAUSER_ROLE(), pauser));
        assertTrue(v2.hasRole(v2.GOV_ROLE(), gov));
    }

    function test_UpgradeRevertsIfNotAuthorized() public {
        MYieldToPrizeDistributorV2 v2Implementation = new MYieldToPrizeDistributorV2();
        
        // Try to upgrade without admin role
        vm.expectRevert();
        v1.upgradeToAndCall(address(v2Implementation), "");
    }

    function test_V2ResetStatistics() public {
        // Upgrade to V2
        MYieldToPrizeDistributorV2 v2Implementation = new MYieldToPrizeDistributorV2();
        vm.prank(admin);
        v1.upgradeToAndCall(address(v2Implementation), "");
        v2 = MYieldToPrizeDistributorV2(address(v1));

        // Generate some yield and claim it
        vm.prank(user1);
        swapFacility.wrapMToken(address(v2), WRAP_AMOUNT);
        v2.enableEarning();
        mToken.simulateYield(address(v2), YIELD_AMOUNT);
        v2.claimYield();

        // Verify statistics exist
        assertEq(v2.yieldClaimCount(), 1);
        assertEq(v2.totalYieldClaimed(), YIELD_AMOUNT);

        // Reset statistics
        vm.prank(admin);
        v2.resetYieldStatistics();

        // Verify statistics are reset
        assertEq(v2.yieldClaimCount(), 0);
        assertEq(v2.totalYieldClaimed(), 0);
        assertEq(v2.averageYieldPerClaim(), 0);
        assertEq(v2.lastClaimTime(), 0);
    }

    function test_V2ResetRevertsIfNotAdmin() public {
        // Upgrade to V2
        MYieldToPrizeDistributorV2 v2Implementation = new MYieldToPrizeDistributorV2();
        vm.prank(admin);
        v1.upgradeToAndCall(address(v2Implementation), "");
        v2 = MYieldToPrizeDistributorV2(address(v1));

        // Try to reset without admin role
        vm.expectRevert();
        v2.resetYieldStatistics();
    }
}
