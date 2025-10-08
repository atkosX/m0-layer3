// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MYieldToPrizeDistributor} from "../src/MYieldToPrizeDistributor.sol";

/**
 * @title Deploy Script for MYieldToPrizeDistributor
 * @notice Deploys the M0 extension to testnet/mainnet
 * @dev Usage:
 *      For testnet: forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 *      For mainnet: forge script script/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify
 */
contract Deploy is Script {
    // ===== M0 Protocol Addresses =====
    // These are placeholder addresses - replace with actual M0 testnet/mainnet addresses
    // See: https://docs.m0.org/deployment-addresses
    
    // Sepolia Testnet Addresses (UPDATE THESE!)
    address constant SEPOLIA_M_TOKEN = address(0); // TODO: Get from M0 team
    address constant SEPOLIA_SWAP_FACILITY = address(0); // TODO: Get from M0 team
    
    // Mainnet Addresses (UPDATE THESE!)
    address constant MAINNET_M_TOKEN = address(0); // TODO: Get from M0 docs
    address constant MAINNET_SWAP_FACILITY = address(0); // TODO: Get from M0 docs
    
    // ===== Your Addresses =====
    // Replace these with your actual addresses
    address constant PRIZE_DISTRIBUTOR = address(0); // Your PrizeDistributor contract
    address constant ADMIN = address(0); // Should be a multisig or governance contract
    address constant FREEZE_MANAGER = address(0); // Should be a separate role address
    address constant YIELD_RECIPIENT_MANAGER = address(0); // Should be a governance address

    function run() external {
        // Validate addresses
        require(PRIZE_DISTRIBUTOR != address(0), "PrizeDistributor address not set");
        require(ADMIN != address(0), "Admin address not set");
        require(FREEZE_MANAGER != address(0), "Freeze manager address not set");
        require(YIELD_RECIPIENT_MANAGER != address(0), "Yield recipient manager address not set");
        
        // Get M0 addresses based on chain
        (address mToken, address swapFacility) = _getM0Addresses();
        
        require(mToken != address(0), "M token address not set for this chain");
        require(swapFacility != address(0), "Swap facility address not set for this chain");
        
        console.log("\n========================================");
        console.log("  DEPLOYING MYieldToPrizeDistributor");
        console.log("========================================\n");
        
        console.log("Network:");
        console.log("  Chain ID:", block.chainid);
        console.log("  Deployer:", msg.sender);
        console.log("");
        
        console.log("M0 Protocol:");
        console.log("  M Token:", mToken);
        console.log("  SwapFacility:", swapFacility);
        console.log("");
        
        console.log("Configuration:");
        console.log("  PrizeDistributor:", PRIZE_DISTRIBUTOR);
        console.log("  Admin:", ADMIN);
        console.log("  Freeze Manager:", FREEZE_MANAGER);
        console.log("  Yield Recipient Manager:", YIELD_RECIPIENT_MANAGER);
        console.log("");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // ===== STEP 1: Deploy Implementation =====
        console.log("Step 1: Deploying implementation...");
        MYieldToPrizeDistributor implementation = new MYieldToPrizeDistributor();
        console.log("  Implementation deployed at:", address(implementation));
        console.log("");

        // ===== STEP 2: Deploy Proxy =====
        console.log("Step 2: Deploying proxy...");
        
        bytes memory initData = abi.encodeWithSelector(
            MYieldToPrizeDistributor.initialize.selector,
            "M Yield to PrizeDistributor",
            "MYPD",
            mToken,
            swapFacility,
            PRIZE_DISTRIBUTOR,
            ADMIN,
            FREEZE_MANAGER,
            YIELD_RECIPIENT_MANAGER
        );
        
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        MYieldToPrizeDistributor extension = MYieldToPrizeDistributor(address(proxy));
        
        console.log("  Proxy deployed at:", address(proxy));
        console.log("");

        vm.stopBroadcast();

        // ===== DEPLOYMENT SUMMARY =====
        console.log("========================================");
        console.log("  DEPLOYMENT SUCCESSFUL!");
        console.log("========================================\n");
        
        console.log("Contract Addresses:");
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
        
        console.log("1. Verify contracts on Etherscan:");
        console.log("   forge verify-contract", address(implementation), "src/MYieldToPrizeDistributor.sol:MYieldToPrizeDistributor --chain", block.chainid);
        console.log("");
        
        console.log("2. Apply for M0 Earner Approval:");
        console.log("   Contact M0 governance to whitelist:", address(extension));
        console.log("   See: https://docs.m0.org/earner-approval");
        console.log("");
        
        console.log("3. Once approved, enable earning:");
        console.log("   Call: extension.enableEarning()");
        console.log("   Caller: Must be admin or authorized role");
        console.log("");
        
        console.log("4. Users can now:");
        console.log("   - Approve M tokens to SwapFacility");
        console.log("   - Call: swapFacility.wrapMToken(address(extension), amount)");
        console.log("   - Receive MYPD extension tokens 1:1");
        console.log("");
        
        console.log("5. Yield claiming:");
        console.log("   - Anyone can call: extension.claimYield()");
        console.log("   - Yield automatically goes to PrizeDistributor");
        console.log("");
        
        console.log("========================================\n");
        
        // Save deployment info to file
        _saveDeploymentInfo(address(extension), address(implementation));
    }

    function _getM0Addresses() internal view returns (address mToken, address swapFacility) {
        if (block.chainid == 11155111) {
            // Sepolia Testnet
            mToken = SEPOLIA_M_TOKEN;
            swapFacility = SEPOLIA_SWAP_FACILITY;
        } else if (block.chainid == 1) {
            // Ethereum Mainnet
            mToken = MAINNET_M_TOKEN;
            swapFacility = MAINNET_SWAP_FACILITY;
        } else {
            // For local testing or other chains
            console.log("  WARNING: Unknown chain ID, using placeholder addresses");
            mToken = address(0);
            swapFacility = address(0);
        }
    }

    function _saveDeploymentInfo(address extension, address implementation) internal {
        string memory deploymentInfo = string(abi.encodePacked(
            "# Deployment Information\n\n",
            "Chain ID: ", vm.toString(block.chainid), "\n",
            "Deployer: ", vm.toString(msg.sender), "\n",
            "Timestamp: ", vm.toString(block.timestamp), "\n\n",
            "## Contract Addresses\n\n",
            "Extension (Proxy): ", vm.toString(extension), "\n",
            "Implementation: ", vm.toString(implementation), "\n\n",
            "## Configuration\n\n",
            "Admin: ", vm.toString(ADMIN), "\n",
            "Freeze Manager: ", vm.toString(FREEZE_MANAGER), "\n",
            "Yield Recipient Manager: ", vm.toString(YIELD_RECIPIENT_MANAGER), "\n",
            "Prize Distributor: ", vm.toString(PRIZE_DISTRIBUTOR), "\n"
        ));
        
        vm.writeFile("./deployments/latest.txt", deploymentInfo);
        console.log("Deployment info saved to: ./deployments/latest.txt");
    }
}
