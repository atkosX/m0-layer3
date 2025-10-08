// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MYieldToPrizeDistributor} from "../src/MYieldToPrizeDistributor.sol";
import {MockMToken} from "../test/mocks/MockMToken.sol";
import {MockSwapFacility} from "../test/mocks/MockSwapFacility.sol";
import {MockPrizeDistributor} from "../test/mocks/MockPrizeDistributor.sol";

/**
 * @title DeployMultiRole
 * @notice Deploys with separate addresses for each role
 * @dev Production-ready deployment with role separation
 */
contract DeployMultiRole is Script {
    function run() external {
        console.log("\n========================================");
        console.log("  DEPLOYING WITH SEPARATE ROLES");
        console.log("========================================\n");
        
        // Get role addresses from environment variables
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address pauser = vm.envAddress("PAUSER_ADDRESS"); 
        address gov = vm.envAddress("GOV_ADDRESS");
        
        console.log("Role Addresses:");
        console.log("Admin (DEFAULT_ADMIN_ROLE):", admin);
        console.log("Pauser (PAUSER_ROLE):", pauser);
        console.log("Gov (GOV_ROLE):", gov);
        console.log("");
        
        // Use admin's private key for deployment
        uint256 deployerPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer:", deployer);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy contracts (same as before)
        MockMToken mToken = new MockMToken();
        MockSwapFacility swapFacility = new MockSwapFacility(address(mToken));
        MockPrizeDistributor prizeDistributor = new MockPrizeDistributor();
        MYieldToPrizeDistributor implementation = new MYieldToPrizeDistributor();
        
        // Deploy proxy with separate role addresses
        bytes memory initData = abi.encodeWithSelector(
            MYieldToPrizeDistributor.initialize.selector,
            "M Yield to PrizeDistributor",
            "MYPD",
            address(mToken),
            address(swapFacility),
            address(prizeDistributor),
            admin,    // DEFAULT_ADMIN_ROLE
            pauser,   // PAUSER_ROLE
            gov       // GOV_ROLE
        );
        
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        MYieldToPrizeDistributor extension = MYieldToPrizeDistributor(address(proxy));
        
        // Setup initial state
        mToken.mint(deployer, 1_000_000e6);
        mToken.approve(address(swapFacility), type(uint256).max);
        
        vm.stopBroadcast();
        
        console.log("========================================");
        console.log("  DEPLOYMENT SUCCESSFUL!");
        console.log("========================================\n");
        
        console.log("Contract Addresses:");
        console.log("Extension (Proxy):", address(extension));
        console.log("Implementation:", address(implementation));
        console.log("MockMToken:", address(mToken));
        console.log("MockSwapFacility:", address(swapFacility));
        console.log("MockPrizeDistributor:", address(prizeDistributor));
        console.log("");
        
        console.log("Role Verification:");
        console.log("Admin has DEFAULT_ADMIN_ROLE:", extension.hasRole(extension.DEFAULT_ADMIN_ROLE(), admin));
        console.log("Pauser has PAUSER_ROLE:", extension.hasRole(extension.PAUSER_ROLE(), pauser));
        console.log("Gov has GOV_ROLE:", extension.hasRole(extension.GOV_ROLE(), gov));
        console.log("");
        
        console.log("Next Steps:");
        console.log("1. Verify roles are correctly assigned");
        console.log("2. Test each role's functionality");
        console.log("3. Transfer roles to multisig contracts if needed");
    }
}
