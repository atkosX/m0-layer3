// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {MYieldToPrizeDistributor} from "./MYieldToPrizeDistributor.sol";

/**
 * @title MYieldToPrizeDistributorV2
 * @notice V2 of the M0 extension with additional tracking features
 * @dev Adds cumulative yield tracking and last claim time
 *      Demonstrates UUPS upgradeability pattern
 */
contract MYieldToPrizeDistributorV2 is MYieldToPrizeDistributor {
    /// @notice Version number for tracking upgrades
    uint256 public constant VERSION = 2;
    
    /// @notice Additional feature: yield claim count
    uint256 public yieldClaimCount;
    
    /// @notice Additional feature: average yield per claim
    uint256 public averageYieldPerClaim;
    
    /// @notice Event emitted when V2 features are used
    event V2FeatureUsed(string feature, uint256 value);

    /**
     * @notice V2 version of claimYield with additional tracking
     * @return yieldAmount The amount of yield claimed
     */
    function claimYield() public override returns (uint256 yieldAmount) {
        yieldAmount = super.claimYield();
        
        if (yieldAmount > 0) {
            // V2 specific tracking
            yieldClaimCount++;
            averageYieldPerClaim = totalYieldClaimed / yieldClaimCount;
            
            emit V2FeatureUsed("yieldClaimCount", yieldClaimCount);
            emit V2FeatureUsed("averageYieldPerClaim", averageYieldPerClaim);
        }
        
        return yieldAmount;
    }
    
    /**
     * @notice V2 specific function: get yield statistics
     * @return claimCount Number of yield claims made
     * @return totalClaimed Total yield claimed across all time
     * @return averagePerClaim Average yield per claim
     * @return lastClaim When the last claim was made
     */
    function getYieldStatistics() external view returns (
        uint256 claimCount,
        uint256 totalClaimed,
        uint256 averagePerClaim,
        uint256 lastClaim
    ) {
        claimCount = yieldClaimCount;
        totalClaimed = totalYieldClaimed;
        averagePerClaim = averageYieldPerClaim;
        lastClaim = lastClaimTime;
    }
    
    /**
     * @notice V2 specific function: reset statistics (admin only)
     * @dev Useful for testing or if statistics need to be reset
     */
    function resetYieldStatistics() external onlyRole(DEFAULT_ADMIN_ROLE) {
        yieldClaimCount = 0;
        averageYieldPerClaim = 0;
        totalYieldClaimed = 0;
        lastClaimTime = 0;
        
        emit V2FeatureUsed("statisticsReset", block.timestamp);
    }
}
