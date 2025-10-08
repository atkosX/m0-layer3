// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MYieldToPrizeDistributor} from "../src/MYieldToPrizeDistributor.sol";
import {MockMToken} from "../test/mocks/MockMToken.sol";
import {MockSwapFacility} from "../test/mocks/MockSwapFacility.sol";
import {MockPrizeDistributor} from "../test/mocks/MockPrizeDistributor.sol";

/**
 * @title Demo Script
 * @notice Demonstrates the complete yield distribution flow
 * @dev Shows before/after balances and yield distribution
 */
contract Demo is Script {
    function run() external {
        console.log("\n========================================");
        console.log("  M0 EXTENSION YIELD DISTRIBUTION DEMO");
        console.log("========================================\n");
        
        // Get deployed addresses from environment
        address extension = vm.envAddress("EXTENSION");
        address mToken = vm.envAddress("M_TOKEN");
        address swapFacility = vm.envAddress("SWAP_FACILITY");
        address prizeDistributor = vm.envAddress("PRIZE_DISTRIBUTOR");
        
        console.log("Using deployed contracts:");
        console.log("Extension:", extension);
        console.log("M Token:", mToken);
        console.log("Swap Facility:", swapFacility);
        console.log("Prize Distributor:", prizeDistributor);
        console.log("");
        
        // Create contract instances
        MYieldToPrizeDistributor ext = MYieldToPrizeDistributor(extension);
        MockMToken m = MockMToken(mToken);
        MockSwapFacility swap = MockSwapFacility(swapFacility);
        MockPrizeDistributor prize = MockPrizeDistributor(prizeDistributor);
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // ===== INITIAL STATE =====
        console.log("=== INITIAL STATE ===");
        uint256 initialMBalance = ext.mBalance();
        uint256 initialTotalSupply = ext.totalSupply();
        uint256 initialPrizeBalance = ext.balanceOf(prizeDistributor);
        uint256 initialYield = ext.yield();
        
        console.log("Extension M Balance:", initialMBalance);
        console.log("Total Supply:", initialTotalSupply);
        console.log("PrizeDistributor Balance:", initialPrizeBalance);
        console.log("Claimable Yield:", initialYield);
        console.log("");
        
        // ===== WRAP TOKENS =====
        console.log("=== WRAPPING 50,000 M TOKENS ===");
        uint256 wrapAmount = 50_000e6; // 50k M tokens
        
        // Check deployer M balance
        uint256 deployerMBalance = m.balanceOf(deployer);
        console.log("Deployer M Balance:", deployerMBalance);
        
        // Wrap tokens
        swap.wrapMToken(extension, wrapAmount);
        console.log("Wrapped", wrapAmount, "M tokens");
        
        // ===== ENABLE EARNING =====
        console.log("\n=== ENABLING EARNING ===");
        ext.enableEarning();
        console.log("Earning enabled");
        
        // ===== SIMULATE YIELD =====
        console.log("\n=== SIMULATING YIELD ===");
        uint256 yieldAmount = 5_000e6; // 5k M tokens yield
        m.simulateYield(extension, yieldAmount);
        console.log("Simulated", yieldAmount, "M tokens yield");
        
        // ===== CHECK STATE BEFORE CLAIM =====
        console.log("\n=== STATE BEFORE YIELD CLAIM ===");
        uint256 beforeMBalance = ext.mBalance();
        uint256 beforeTotalSupply = ext.totalSupply();
        uint256 beforePrizeBalance = ext.balanceOf(prizeDistributor);
        uint256 beforeYield = ext.yield();
        
        console.log("Extension M Balance:", beforeMBalance);
        console.log("Total Supply:", beforeTotalSupply);
        console.log("PrizeDistributor Balance:", beforePrizeBalance);
        console.log("Claimable Yield:", beforeYield);
        console.log("");
        
        // ===== CLAIM YIELD =====
        console.log("=== CLAIMING YIELD ===");
        uint256 claimedYield = ext.claimYield();
        console.log("Claimed yield:", claimedYield);
        
        // ===== FINAL STATE =====
        console.log("\n=== FINAL STATE ===");
        uint256 finalMBalance = ext.mBalance();
        uint256 finalTotalSupply = ext.totalSupply();
        uint256 finalPrizeBalance = ext.balanceOf(prizeDistributor);
        uint256 finalYield = ext.yield();
        
        console.log("Extension M Balance:", finalMBalance);
        console.log("Total Supply:", finalTotalSupply);
        console.log("PrizeDistributor Balance:", finalPrizeBalance);
        console.log("Remaining Yield:", finalYield);
        console.log("");
        
        // ===== VERIFICATION =====
        console.log("=== VERIFICATION ===");
        console.log("Yield Distribution Success!");
        console.log("PrizeDistributor received:", finalPrizeBalance, "tokens");
        console.log("Total supply increased by:", finalTotalSupply - beforeTotalSupply);
        console.log("M balance matches total supply:", finalMBalance == finalTotalSupply);
        console.log("No remaining yield:", finalYield == 0);
        
        vm.stopBroadcast();
        
        console.log("\n========================================");
        console.log("  DEMO COMPLETED SUCCESSFULLY!");
        console.log("========================================\n");
    }
}