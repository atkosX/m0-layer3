// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import {MYieldToPrizeDistributor} from "../src/MYieldToPrizeDistributor.sol";
import {MockMToken} from "../test/mocks/MockMToken.sol";
import {MockSwapFacility} from "../test/mocks/MockSwapFacility.sol";
import {MockPrizeDistributor} from "../test/mocks/MockPrizeDistributor.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title Demo Script
 * @notice Demonstrates MYieldToOne functionality with balance printing
 * @dev Shows before/after balances for yield distribution
 */
contract Demo is Script {
    function run() external {
        vm.startBroadcast();
        
        console2.log("\n========================================");
        console2.log("  MYIELDTOONE DEMO - BALANCE TRACKING");
        console2.log("========================================\n");
        
        // Deploy mock contracts
        console2.log("Deploying mock contracts...");
        MockMToken mToken = new MockMToken();
        MockSwapFacility swapFacility = new MockSwapFacility(address(mToken));
        MockPrizeDistributor prizeDistributor = new MockPrizeDistributor();
        
        console2.log("M Token:", address(mToken));
        console2.log("SwapFacility:", address(swapFacility));
        console2.log("PrizeDistributor:", address(prizeDistributor));

        // Deploy MYieldToOne
        console2.log("\nDeploying MYieldToOne...");
        MYieldToPrizeDistributor implementation = new MYieldToPrizeDistributor();
        
        bytes memory initData = abi.encodeWithSelector(
            MYieldToPrizeDistributor.initialize.selector,
            "M Yield to PrizeDistributor",
            "MYPD",
            address(mToken),
            address(swapFacility),
            address(prizeDistributor),
            msg.sender, // admin
            msg.sender, // gov
            msg.sender  // pauser
        );
        
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        MYieldToPrizeDistributor extension = MYieldToPrizeDistributor(address(proxy));
        
        console2.log("MYieldToOne deployed at:", address(extension));

        // Setup initial state
        console2.log("\nSetting up initial state...");
        mToken.mint(msg.sender, 1_000_000e6); // 1M M tokens
        mToken.approve(address(swapFacility), type(uint256).max);
        console2.log("Minted 1M M tokens to deployer");

        // Wrap some M tokens
        uint256 wrapAmount = 100_000e6; // 100k M tokens
        console2.log("\nWrapping", wrapAmount / 1e6, "M tokens...");
        swapFacility.wrapMToken(address(extension), wrapAmount);
        console2.log("Wrapped tokens successfully");

        // Check initial balances
        console2.log("\n=== INITIAL BALANCES ===");
        uint256 mTokenBalance = mToken.balanceOf(address(extension));
        uint256 extensionSupply = extension.totalSupply();
        uint256 prizeDistributorBalance = extension.balanceOf(address(prizeDistributor));
        uint256 claimableYield = extension.yield();
        
        console2.log("Extension M token balance:", mTokenBalance / 1e6, "M");
        console2.log("Extension total supply:", extensionSupply / 1e6, "tokens");
        console2.log("PrizeDistributor balance:", prizeDistributorBalance / 1e6, "tokens");
        console2.log("Claimable yield:", claimableYield / 1e6, "M");

        // Enable earning
        console2.log("\nEnabling earning...");
        extension.enableEarning();
        console2.log("Earning enabled:", extension.earningActive());

        // Simulate yield accrual
        uint256 yieldAmount = 10_000e6; // 10k M yield
        console2.log("\nSimulating", yieldAmount / 1e6, "M yield...");
        mToken.simulateYield(address(extension), yieldAmount);
        console2.log("Yield simulated successfully");

        // Check balances after yield simulation
        console2.log("\n=== BALANCES AFTER YIELD SIMULATION ===");
        mTokenBalance = mToken.balanceOf(address(extension));
        extensionSupply = extension.totalSupply();
        claimableYield = extension.yield();
        
        console2.log("Extension M token balance:", mTokenBalance / 1e6, "M");
        console2.log("Extension total supply:", extensionSupply / 1e6, "tokens");
        console2.log("Claimable yield:", claimableYield / 1e6, "M");

        // Record balances before distribution
        console2.log("\n=== BALANCES BEFORE DISTRIBUTION ===");
        prizeDistributorBalance = extension.balanceOf(address(prizeDistributor));
        uint256 totalYieldClaimed = extension.totalYieldClaimed();
        uint256 lastClaimTime = extension.lastClaimTime();
        
        console2.log("PrizeDistributor balance:", prizeDistributorBalance / 1e6, "tokens");
        console2.log("Total yield claimed:", totalYieldClaimed / 1e6, "M");
        console2.log("Last claim time:", lastClaimTime);

        // Distribute yield
        console2.log("\nDistributing yield...");
        uint256 distributedAmount = extension.claimYield();
        console2.log("Yield distributed:", distributedAmount / 1e6, "M");

        // Check balances after distribution
        console2.log("\n=== BALANCES AFTER DISTRIBUTION ===");
        mTokenBalance = mToken.balanceOf(address(extension));
        extensionSupply = extension.totalSupply();
        prizeDistributorBalance = extension.balanceOf(address(prizeDistributor));
        totalYieldClaimed = extension.totalYieldClaimed();
        lastClaimTime = extension.lastClaimTime();
        
        console2.log("Extension M token balance:", mTokenBalance / 1e6, "M");
        console2.log("Extension total supply:", extensionSupply / 1e6, "tokens");
        console2.log("PrizeDistributor balance:", prizeDistributorBalance / 1e6, "tokens");
        console2.log("Total yield claimed:", totalYieldClaimed / 1e6, "M");
        console2.log("Last claim time:", lastClaimTime);

        // Summary
        console2.log("\n=== DISTRIBUTION SUMMARY ===");
        console2.log("Yield distributed to PrizeDistributor:", distributedAmount / 1e6, "M");
        console2.log("PrizeDistributor received:", prizeDistributorBalance / 1e6, "extension tokens");
        console2.log("Distribution successful:", distributedAmount > 0 ? "YES" : "NO");
        
        console2.log("\n========================================");
        console2.log("  DEMO COMPLETE - SUCCESS!");
        console2.log("========================================\n");

        vm.stopBroadcast();
    }
}