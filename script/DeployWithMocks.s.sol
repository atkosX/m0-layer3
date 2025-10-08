// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MYieldToPrizeDistributor} from "../src/MYieldToPrizeDistributor.sol";
import {MockMToken} from "../test/mocks/MockMToken.sol";
import {MockSwapFacility} from "../test/mocks/MockSwapFacility.sol";
import {MockPrizeDistributor} from "../test/mocks/MockPrizeDistributor.sol";

/**
 * @title DeployWithMocks
 * @notice Deploys the full system with mocks for immediate testing
 * @dev Perfect for testing on Sepolia before M0 integration
 */
contract DeployWithMocks is Script {
    function run() external {
        console.log("\n========================================");
        console.log("  DEPLOYING FULL SYSTEM WITH MOCKS");
        console.log("========================================\n");
        
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // For testing, admin = deployer
        address admin = deployer;
        address pauser = deployer;
        address gov = deployer;
        
        vm.startBroadcast(deployerPrivateKey);

        // ===== STEP 1: Deploy Mock M Token =====
        console.log("Step 1: Deploying MockMToken...");
        MockMToken mToken = new MockMToken();
        console.log("  MockMToken:", address(mToken));
        console.log("");

        // ===== STEP 2: Deploy Mock SwapFacility =====
        console.log("Step 2: Deploying MockSwapFacility...");
        MockSwapFacility swapFacility = new MockSwapFacility(address(mToken));
        console.log("  MockSwapFacility:", address(swapFacility));
        console.log("");

        // ===== STEP 3: Deploy Mock PrizeDistributor =====
        console.log("Step 3: Deploying MockPrizeDistributor...");
        MockPrizeDistributor prizeDistributor = new MockPrizeDistributor();
        console.log("  MockPrizeDistributor:", address(prizeDistributor));
        console.log("");

        // ===== STEP 4: Deploy Extension Implementation =====
        console.log("Step 4: Deploying MYieldToPrizeDistributor implementation...");
        MYieldToPrizeDistributor implementation = new MYieldToPrizeDistributor();
        console.log("  Implementation:", address(implementation));
        console.log("");

        // ===== STEP 5: Deploy Proxy =====
        console.log("Step 5: Deploying proxy...");
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
        MYieldToPrizeDistributor extension = MYieldToPrizeDistributor(address(proxy));
        
        console.log("  Proxy:", address(proxy));
        console.log("");

        // ===== STEP 6: Setup Initial State =====
        console.log("Step 6: Setting up initial state...");
        
        // Mint some M tokens to deployer for testing
        mToken.mint(deployer, 1_000_000e6);
        console.log("  Minted 1M M tokens to deployer");
        
        // Approve swap facility
        mToken.approve(address(swapFacility), type(uint256).max);
        console.log("  Approved SwapFacility");
        console.log("");

        vm.stopBroadcast();

        // ===== DEPLOYMENT SUMMARY =====
        console.log("========================================");
        console.log("  DEPLOYMENT SUCCESSFUL!");
        console.log("========================================\n");
        
        console.log("Contract Addresses:");
        console.log("----------------------------------------");
        console.log("MockMToken:", address(mToken));
        console.log("MockSwapFacility:", address(swapFacility));
        console.log("MockPrizeDistributor:", address(prizeDistributor));
        console.log("Extension (Proxy):", address(extension));
        console.log("Implementation:", address(implementation));
        console.log("");
        
        console.log("Extension Info:");
        console.log("----------------------------------------");
        console.log("Name:", extension.name());
        console.log("Symbol:", extension.symbol());
        console.log("Total Supply:", extension.totalSupply());
        console.log("Earning Active:", extension.earningActive());
        console.log("");
        
        console.log("Quick Test Commands:");
        console.log("----------------------------------------");
        console.log("");
        console.log("# Save these addresses to .env:");
        console.log('export EXTENSION="%s"', address(extension));
        console.log('export M_TOKEN="%s"', address(mToken));
        console.log('export SWAP_FACILITY="%s"', address(swapFacility));
        console.log('export PRIZE_DISTRIBUTOR="%s"', address(prizeDistributor));
        console.log("");
        
        console.log("# 1. Wrap 100k M tokens:");
        console.log("cast send $SWAP_FACILITY 'wrapMToken(address,uint256)' \\");
        console.log("  $EXTENSION 100000000000 \\");
        console.log("  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL");
        console.log("");
        
        console.log("# 2. Enable earning:");
        console.log("cast send $EXTENSION 'enableEarning()' \\");
        console.log("  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL");
        console.log("");
        
        console.log("# 3. Simulate yield (10k M):");
        console.log("cast send $M_TOKEN 'simulateYield(address,uint256)' \\");
        console.log("  $EXTENSION 10000000000 \\");
        console.log("  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL");
        console.log("");
        
        console.log("# 4. Check claimable yield:");
        console.log("cast call $EXTENSION 'yield()' --rpc-url $SEPOLIA_RPC_URL");
        console.log("");
        
        console.log("# 5. Claim yield:");
        console.log("cast send $EXTENSION 'claimYield()' \\");
        console.log("  --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL");
        console.log("");
        
        console.log("# 6. Check PrizeDistributor balance:");
        console.log("cast call $EXTENSION 'balanceOf(address)' \\");
        console.log("  $PRIZE_DISTRIBUTOR --rpc-url $SEPOLIA_RPC_URL");
        console.log("");
        
        console.log("========================================");
        console.log("  READY TO TEST!");
        console.log("========================================\n");
    }
}

