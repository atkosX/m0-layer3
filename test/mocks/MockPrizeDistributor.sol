// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "../../interfaces/IPrizeDistributor.sol";

/**
 * @title MockPrizeDistributor
 * @notice Mock prize distributor for testing MYieldToPrizeDistributor yield distribution
 * @dev Tracks received yield and epochs for verification
 *      In real implementation, would unwrap extension tokens to M and distribute prizes
 */
contract MockPrizeDistributor is IPrizeDistributor {
    uint256 public currentEpochValue;
    mapping(uint256 => uint256) public epochYields;
    uint256[] public epochHistory;
    uint256 public totalReceived;

    event YieldReceived(uint256 amount, uint256 epoch, address from);

    constructor() {
        currentEpochValue = 1;
    }

    function distributeYield(uint256 amount, uint256 epoch) external override {
        require(amount > 0, "MockPrizeDistributor: amount must be > 0");

        // Update epoch if needed
        if (epoch > currentEpochValue) {
            currentEpochValue = epoch;
        }

        epochYields[epoch] += amount;
        epochHistory.push(epoch);
        totalReceived += amount;

        // In a real implementation, this would distribute to prize winners
        // For testing, we just track the received amount

        emit YieldReceived(amount, epoch, msg.sender);
    }

    function currentEpoch() external view override returns (uint256) {
        return currentEpochValue;
    }

    function epochYield(uint256 epoch) external view override returns (uint256) {
        return epochYields[epoch];
    }

    // Test helper functions
    function setCurrentEpoch(uint256 epoch) external {
        currentEpochValue = epoch;
    }

    function incrementEpoch() external {
        currentEpochValue++;
    }

    function getEpochHistory() external view returns (uint256[] memory) {
        return epochHistory;
    }

    function getTotalYieldReceived() external view returns (uint256) {
        return totalReceived;
    }
}
