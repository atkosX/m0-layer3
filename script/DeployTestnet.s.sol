// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MYieldToPrizeDistributor} from "../src/MYieldToPrizeDistributor.sol";

/**
 * @title DeployTestnet Script
 * @notice Deploys MYieldToPrizeDistributor to testnet using environment variables
 * @dev Usage: forge script script/DeployTestnet.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 */
contract DeployTestnet is Script {
    function run() external {
        // Read from environment variables
        address mToken = vm.envAddress("SEPOLIA_M_TOKEN");
        address swapFacility = vm.envAddress("SEPOLIA_SWAP_FACILITY");
        address prizeDistributor = vm.envAddress("PRIZE_DISTRIBUTOR");
        address admin = vm.envAddress("ADMIN");
        address freezeManager = vm.envAddress("FREEZE_MANAGER");
        address yieldRecipientManager = vm.envAddress("YIELD_RECIPIENT_MANAGER");
        
        console.log("\n========================================");
        console.log("  DEPLOYING TO TESTNET");
        console.log("========================================\n");
        
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", msg.sender);
        console.log("");
        
        console.log("M0 Configuration:");
        console.log("  M Token:", mToken);
        console.log("  SwapFacility:", swapFacility);
        console.log("");
        
        console.log("Your Configuration:");
        console.log("  PrizeDistributor:", prizeDistributor);
        console.log("  Admin:", admin);
        console.log("  Freeze Manager:", freezeManager);
        console.log("  Yield Recipient Manager:", yieldRecipientManager);
        console.log("");

        // Validate addresses
        require(mToken != address(0), "M Token address not set");
        require(swapFacility != address(0), "SwapFacility address not set");
        require(prizeDistributor != address(0), "PrizeDistributor address not set");
        require(admin != address(0), "Admin address not set");
        require(freezeManager != address(0), "Freeze Manager address not set");
        require(yieldRecipientManager != address(0), "Yield Recipient Manager address not set");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        console.log("Step 1: Deploying implementation...");
        MYieldToPrizeDistributor implementation = new MYieldToPrizeDistributor();
        console.log("  Implementation:", address(implementation));
        console.log("");

        // Deploy proxy
        console.log("Step 2: Deploying proxy...");
        bytes memory initData = abi.encodeWithSelector(
            MYieldToPrizeDistributor.initialize.selector,
            "M Yield to PrizeDistributor",
            "MYPD",
            mToken,
            swapFacility,
            prizeDistributor,
            admin,
            freezeManager,
            yieldRecipientManager
        );
        
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        MYieldToPrizeDistributor extension = MYieldToPrizeDistributor(address(proxy));
        
        console.log("  Proxy:", address(proxy));
        console.log("");

        vm.stopBroadcast();

        // Display deployment info
        console.log("========================================");
        console.log("  DEPLOYMENT SUCCESSFUL!");
        console.log("========================================\n");
        
        console.log("Deployed Contracts:");
        console.log("  Extension (Proxy):", address(extension));
        console.log("  Implementation:", address(implementation));
        console.log("");
        
        console.log("Token Info:");
        console.log("  Name:", extension.name());
        console.log("  Symbol:", extension.symbol());
        console.log("  Decimals:", extension.decimals());
        console.log("");
        
        console.log("Configuration:");
        console.log("  M Token:", address(extension.mToken()));
        console.log("  SwapFacility:", address(extension.swapFacility()));
        console.log("  Yield Recipient:", extension.yieldRecipient());
        console.log("  Earning Active:", extension.earningActive());
        console.log("");
        
        console.log("========================================");
        console.log("  NEXT STEPS");
        console.log("========================================\n");
        
        console.log("1. Save these addresses:");
        console.log("   Extension:", address(extension));
        console.log("   Implementation:", address(implementation));
        console.log("");
        
        console.log("2. Verify on Etherscan (if not auto-verified):");
        console.log("   forge verify-contract", address(implementation));
        console.log("   src/MYieldToPrizeDistributor.sol:MYieldToPrizeDistributor");
        console.log("   --chain", block.chainid);
        console.log("");
        
        console.log("3. Apply for M0 Earner Approval:");
        console.log("   Contact M0 governance to whitelist:", address(extension));
        console.log("");
        
        console.log("4. Once approved, enable earning:");
        console.log("   cast send", address(extension));
        console.log("   'enableEarning()' --private-key $PRIVATE_KEY");
        console.log("");
        
        console.log("5. Test with our scripts!");
        console.log("");
    }
}

