// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title IPrizeDistributor Interface
 * @notice Interface for receiving yield distributions from MYieldToOne
 * @dev Simple interface that can be implemented by various prize distribution systems
 */
interface IPrizeDistributor {
    /**
     * @notice Receive yield distribution from MYieldToOne
     * @param amount The amount of yield tokens received
     * @param epoch The epoch number for tracking distributions
     */
    function distributeYield(uint256 amount, uint256 epoch) external;

    /**
     * @notice Get the current epoch number
     * @return The current epoch for yield distribution tracking
     */
    function currentEpoch() external view returns (uint256);

    /**
     * @notice Get the total yield received in a specific epoch
     * @param epoch The epoch to query
     * @return The total yield amount for that epoch
     */
    function epochYield(uint256 epoch) external view returns (uint256);
}
