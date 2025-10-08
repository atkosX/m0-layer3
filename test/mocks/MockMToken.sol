// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IMTokenLike} from "../../interfaces/IMTokenLike.sol";

/**
 * @title MockMToken
 * @notice Mock M Token for testing
 * @dev Simulates M0's M token with earning functionality
 */
contract MockMToken is IMTokenLike {
    string public constant name = "M";
    string public constant symbol = "M";
    uint8 public constant decimals = 6;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _earning;
    
    uint256 private _totalSupply;
    uint256 private _currentIndex = 1e12; // Start at 1e12

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event StartedEarning(address indexed account);
    event StoppedEarning(address indexed account, address indexed by);

    function mint(address account, uint256 amount) external {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function simulateYield(address account, uint256 yieldAmount) external {
        // Simulate yield by adding to balance without changing total supply
        _balances[account] += yieldAmount;
    }

    function startEarning() external override {
        _earning[msg.sender] = true;
        emit StartedEarning(msg.sender);
    }

    function stopEarning(address account) external override {
        _earning[account] = false;
        emit StoppedEarning(account, msg.sender);
    }

    function currentIndex() external view override returns (uint256) {
        return _currentIndex;
    }

    function setCurrentIndex(uint256 index) external {
        _currentIndex = index;
    }

    function isEarning(address account) external view override returns (bool) {
        return _earning[account];
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(_balances[from] >= amount, "Insufficient balance");
        require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
}


