// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMTokenLike} from "../interfaces/IMTokenLike.sol";
import {ISwapFacility} from "../interfaces/ISwapFacility.sol";
import {IPrizeDistributor} from "../interfaces/IPrizeDistributor.sol";

/**
 * @title  MYieldToPrizeDistributor
 * @notice M0 Extension Token that wraps M and routes 100% of yield to a PrizeDistributor
 * @dev    Follows M0's official extension architecture:
 *         - Users wrap M via SwapFacility → receive extension tokens
 *         - Extension contract holds M and earns yield
 *         - Yield = M balance - total supply of extension tokens
 *         - claimYield() mints extension tokens to PrizeDistributor
 *         - PrizeDistributor can unwrap to get M for prizes
 *
 * ARCHITECTURE:
 * ============
 * This follows M0's MYieldToOne pattern where:
 * 1. totalSupply tracks wrapped M tokens (1:1)
 * 2. M balance > totalSupply = yield accrued
 * 3. Yield is "claimed" by minting extension tokens to recipient
 * 4. Recipient unwraps tokens to get actual M
 * 
 * @author Your Team
 */
contract MYieldToPrizeDistributor is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    /// @notice Role that can change the yield recipient (PrizeDistributor)
    bytes32 public constant GOV_ROLE = keccak256("GOV_ROLE");
    
    /// @notice Role that can pause/unpause the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice The M token contract (immutable in production, set in tests)
    IMTokenLike public mToken;
    
    /// @notice The SwapFacility contract (immutable in production, set in tests)  
    ISwapFacility public swapFacility;

    /// @notice The PrizeDistributor that receives all yield
    address public yieldRecipient;

    /// @notice Whether earning is currently active
    bool public earningActive;

    /// @notice Total supply of extension tokens
    uint256 public totalSupply;

    /// @notice Balance of extension tokens per account
    mapping(address => uint256) public balanceOf;

    /// @notice Allowances for transfer approvals
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice Frozen accounts (cannot transfer)
    mapping(address => bool) public frozen;

    /// @notice Token name
    string public name;

    /// @notice Token symbol
    string public symbol;

    /// @notice Token decimals (matches M token - 6 decimals)
    uint8 public constant decimals = 6;

    /* ============ Events ============ */

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event YieldClaimed(uint256 amount, address indexed recipient);
    event YieldRecipientSet(address indexed oldRecipient, address indexed newRecipient);
    event EarningEnabled(uint256 indexed atIndex);
    event EarningDisabled(uint256 indexed atIndex);
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);
    event Wrapped(address indexed account, uint256 amount);
    event Unwrapped(address indexed account, uint256 amount);

    /* ============ Errors ============ */

    error ZeroAddress();
    error ZeroAmount();
    error InsufficientBalance();
    error InsufficientAllowance();
    error AccountIsFrozen(address account);
    error EarningAlreadyEnabled();
    error EarningNotEnabled();
    error NotSwapFacility();

    /* ============ Constructor ============ */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initializer ============ */

    /**
     * @notice Initializes the MYieldToPrizeDistributor token
     * @param name_                  Token name (e.g. "M Yield to PrizeDistributor")
     * @param symbol_                Token symbol (e.g. "MYPD")
     * @param mToken_                Address of the M token
     * @param swapFacility_          Address of the SwapFacility
     * @param prizeDistributor_      Address of the PrizeDistributor (yield recipient)
     * @param admin_                 Address with DEFAULT_ADMIN_ROLE
     * @param pauser_                Address with PAUSER_ROLE
     * @param gov_                   Address with GOV_ROLE
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address mToken_,
        address swapFacility_,
        address prizeDistributor_,
        address admin_,
        address pauser_,
        address gov_
    ) external initializer {
        if (mToken_ == address(0)) revert ZeroAddress();
        if (swapFacility_ == address(0)) revert ZeroAddress();
        if (prizeDistributor_ == address(0)) revert ZeroAddress();
        if (admin_ == address(0)) revert ZeroAddress();
        if (pauser_ == address(0)) revert ZeroAddress();
        if (gov_ == address(0)) revert ZeroAddress();

        __UUPSUpgradeable_init();
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        name = name_;
        symbol = symbol_;
        mToken = IMTokenLike(mToken_);
        swapFacility = ISwapFacility(swapFacility_);
        yieldRecipient = prizeDistributor_;
        earningActive = false;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(PAUSER_ROLE, pauser_);
        _grantRole(GOV_ROLE, gov_);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Wrap M tokens into extension tokens (called by SwapFacility)
     * @param recipient Address receiving extension tokens
     * @param amount Amount of M tokens to wrap
     */
    function wrap(address recipient, uint256 amount) external {
        if (msg.sender != address(swapFacility)) revert NotSwapFacility();
        if (amount == 0) revert ZeroAmount();
        
        _mint(recipient, amount);
        
        emit Wrapped(recipient, amount);
    }

    /**
     * @notice Unwrap extension tokens back to M (called by SwapFacility)
     * @param account Address unwrapping tokens
     * @param amount Amount of extension tokens to unwrap
     */
    function unwrap(address account, uint256 amount) external {
        if (msg.sender != address(swapFacility)) revert NotSwapFacility();
        if (amount == 0) revert ZeroAmount();
        
        _burn(account, amount);
        
        emit Unwrapped(account, amount);
    }

    /**
     * @notice Enable earning for this extension contract
     * @dev Calls M token's startEarning() function
     */
    function enableEarning() external whenNotPaused {
        if (earningActive) revert EarningAlreadyEnabled();
        
        uint256 currentIndex = mToken.currentIndex();
        earningActive = true;
        
        mToken.startEarning();
        
        emit EarningEnabled(currentIndex);
    }

    /**
     * @notice Disable earning for this extension contract
     * @dev Calls M token's stopEarning() function
     */
    function disableEarning() external whenNotPaused {
        if (!earningActive) revert EarningNotEnabled();
        
        uint256 currentIndex = mToken.currentIndex();
        earningActive = false;
        
        mToken.stopEarning(address(this));
        
        emit EarningDisabled(currentIndex);
    }

    /**
     * @notice Claims yield and mints extension tokens to PrizeDistributor
     * @return yieldAmount The amount of yield claimed
     * @dev Yield = M balance - total supply
     *      Mints extension tokens to yieldRecipient (PrizeDistributor)
     *      PrizeDistributor can then unwrap to get actual M
     */
    function claimYield() public nonReentrant whenNotPaused returns (uint256 yieldAmount) {
        yieldAmount = _calculateYield();
        
        if (yieldAmount == 0) return 0;
        
        // Mint extension tokens to PrizeDistributor
        _mint(yieldRecipient, yieldAmount);
        
        // Notify PrizeDistributor with epoch information
        IPrizeDistributor(yieldRecipient).distributeYield(yieldAmount, block.timestamp);
        
        emit YieldClaimed(yieldAmount, yieldRecipient);
        
        return yieldAmount;
    }

    /**
     * @notice Sets a new yield recipient (PrizeDistributor)
     * @param newYieldRecipient Address of the new yield recipient
     */
    function setYieldRecipient(address newYieldRecipient) external onlyRole(GOV_ROLE) {
        if (newYieldRecipient == address(0)) revert ZeroAddress();
        
        // Claim yield for current recipient first
        if (_calculateYield() > 0) {
            claimYield();
        }
        
        address oldRecipient = yieldRecipient;
        yieldRecipient = newYieldRecipient;
        
        emit YieldRecipientSet(oldRecipient, newYieldRecipient);
    }

    /**
     * @notice Freezes an account (prevents transfers)
     * @param account Address to freeze
     */
    function freeze(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        frozen[account] = true;
        emit AccountFrozen(account);
    }

    /**
     * @notice Unfreezes an account
     * @param account Address to unfreeze
     */
    function unfreeze(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        frozen[account] = false;
        emit AccountUnfrozen(account);
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ============ ERC20 Functions ============ */

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance();
        
        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    /* ============ View Functions ============ */

    /**
     * @notice Calculate current claimable yield
     * @return Current yield amount (M balance - total supply)
     */
    function yield() external view returns (uint256) {
        return _calculateYield();
    }

    /**
     * @notice Check if earning is enabled
     * @return True if earning is enabled
     */
    function isEarningEnabled() external view returns (bool) {
        return earningActive;
    }

    /**
     * @notice Get current M balance of this contract
     * @return M token balance
     */
    function mBalance() external view returns (uint256) {
        return IERC20(address(mToken)).balanceOf(address(this));
    }

    /* ============ Internal Functions ============ */

    function _calculateYield() internal view returns (uint256) {
        uint256 mBalance = IERC20(address(mToken)).balanceOf(address(this));
        uint256 supply = totalSupply;
        
        return mBalance > supply ? mBalance - supply : 0;
    }

    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) revert ZeroAddress();
        
        totalSupply += amount;
        balanceOf[account] += amount;
        
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        if (balanceOf[account] < amount) revert InsufficientBalance();
        
        unchecked {
            balanceOf[account] -= amount;
            totalSupply -= amount;
        }
        
        emit Transfer(account, address(0), amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        if (frozen[from]) revert AccountIsFrozen(from);
        if (frozen[to]) revert AccountIsFrozen(to);
        if (balanceOf[from] < amount) revert InsufficientBalance();
        
        unchecked {
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
        }
        
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0) || spender == address(0)) revert ZeroAddress();
        
        allowance[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
