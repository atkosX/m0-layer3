// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title  IMTokenLike
 * @notice Interface for M0's M Token that extension contracts interact with
 * @dev    Based on M0's official M token interface for earner management
 */
interface IMTokenLike {
    /**
     * @notice Start earning for the caller
     * @dev Called by extension contracts to begin earning yield on their M balance
     */
    function startEarning() external;

    /**
     * @notice Stop earning for a specific account
     * @param account The account to stop earning for
     * @dev Called by extension contracts to stop earning yield
     */
    function stopEarning(address account) external;

    /**
     * @notice Get the current index for yield calculation
     * @return The current index value
     * @dev Used to track when earning was enabled/disabled
     */
    function currentIndex() external view returns (uint256);

    /**
     * @notice Check if an account is earning
     * @param account The account to check
     * @return True if the account is earning
     */
    function isEarning(address account) external view returns (bool);

    /**
     * @notice Get the balance of an account
     * @param account The account to query
     * @return The M token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Transfer M tokens
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return True if successful
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @notice Transfer M tokens from one address to another
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return True if successful
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /**
     * @notice Approve spending of M tokens
     * @param spender Address to approve
     * @param amount Amount to approve
     * @return True if successful
     */
    function approve(address spender, uint256 amount) external returns (bool);
}


