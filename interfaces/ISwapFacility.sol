// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title  ISwapFacility
 * @notice Interface for M0's SwapFacility that handles wrapping/unwrapping
 * @dev    SwapFacility is the authorized contract that can call wrap/unwrap on extensions
 */
interface ISwapFacility {
    /**
     * @notice Wrap M tokens into extension tokens
     * @param extension The extension contract to wrap into
     * @param amount Amount of M tokens to wrap
     * @return Amount of extension tokens received
     */
    function wrapMToken(address extension, uint256 amount) external returns (uint256);

    /**
     * @notice Unwrap extension tokens back to M
     * @param extension The extension contract to unwrap from
     * @param amount Amount of extension tokens to unwrap
     * @return Amount of M tokens received
     */
    function unwrapMToken(address extension, uint256 amount) external returns (uint256);

    /**
     * @notice Get the original message sender (for access control in extensions)
     * @return The address that initiated the wrap/unwrap call
     * @dev Extensions use this to check who called through SwapFacility
     */
    function msgSender() external view returns (address);
}


