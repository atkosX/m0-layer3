// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ISwapFacility} from "../../interfaces/ISwapFacility.sol";
import {IMTokenLike} from "../../interfaces/IMTokenLike.sol";

/**
 * @title MockSwapFacility
 * @notice Mock SwapFacility for testing wrap/unwrap functionality
 * @dev Simulates M0's SwapFacility which is the authorized contract for wrapping/unwrapping
 */
contract MockSwapFacility is ISwapFacility, Test {
    IMTokenLike public mToken;
    address private _msgSender;

    constructor(address mToken_) {
        mToken = IMTokenLike(mToken_);
    }

    /**
     * @notice Wrap M tokens into extension tokens
     * @param extension The extension contract to wrap into
     * @param amount Amount of M tokens to wrap
     * @return Amount of extension tokens minted
     */
    function wrapMToken(address extension, uint256 amount) external override returns (uint256) {
        // Transfer M from user to extension
        require(mToken.transferFrom(msg.sender, extension, amount), "M transfer failed");
        
        // Set msg.sender for the extension to check
        _msgSender = msg.sender;
        
        // Call wrap on extension (extension mints tokens to recipient)
        (bool success, bytes memory data) = extension.call(
            abi.encodeWithSignature("wrap(address,uint256)", msg.sender, amount)
        );
        require(success, "Wrap failed");
        
        // Clear msg.sender
        _msgSender = address(0);
        
        return amount;
    }

    /**
     * @notice Unwrap extension tokens back to M
     * @param extension The extension contract to unwrap from
     * @param amount Amount of extension tokens to unwrap
     * @return Amount of M tokens returned
     */
    function unwrapMToken(address extension, uint256 amount) external override returns (uint256) {
        // Set msg.sender for the extension to check
        _msgSender = msg.sender;
        
        // Call unwrap on extension (extension burns tokens)
        (bool success, bytes memory data) = extension.call(
            abi.encodeWithSignature("unwrap(address,uint256)", msg.sender, amount)
        );
        require(success, "Unwrap failed");
        
        // Clear msg.sender
        _msgSender = address(0);
        
        // Transfer M from extension to user
        // In real M0, SwapFacility is authorized to pull M from extension
        // In our mock, we simulate this by trying prank first, falling back to direct transfer
        uint256 extensionMBalance = mToken.balanceOf(extension);
        require(extensionMBalance >= amount, "Insufficient M in extension");
        
        // Try to prank (works in tests, but not during broadcast)
        try this._transferMFromExtension(extension, msg.sender, amount) {
            // Success via prank
        } catch {
            // In broadcast mode, prank doesn't work, so we just verify the balance
            // In production, SwapFacility would be authorized to pull funds
            require(extensionMBalance >= amount, "Insufficient M balance");
        }
        
        return amount;
    }

    /// @dev Helper function to handle transferring M from extension
    function _transferMFromExtension(address extension, address to, uint256 amount) external {
        require(msg.sender == address(this), "Only self");
        vm.prank(extension);
        require(mToken.transfer(to, amount), "M transfer failed");
    }

    /**
     * @notice Get the original message sender
     * @return The address that initiated the wrap/unwrap call
     */
    function msgSender() external view override returns (address) {
        return _msgSender == address(0) ? msg.sender : _msgSender;
    }
}

