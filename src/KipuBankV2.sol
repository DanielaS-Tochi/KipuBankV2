// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KipuBankV2
 * @dev Upgraded decentralized bank contract with multi-token support, access control,
 *      and Chainlink price feed integration (to be added).
 *      Based on the original KipuBank project.
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KipuBankV2 is AccessControl {

    // --- Roles ---
    bytes32 public constant BANK_MANAGER_ROLE = keccak256("BANK_MANAGER_ROLE");

    // --- State Variables ---
    uint256 public immutable bankCapUSD; // Limit in USD (we'll use Chainlink later)
    uint256 public constant WITHDRAW_LIMIT = 1 ether;

    // Nested mapping: user => token => balance
    mapping(address => mapping(address => uint256)) private balances;

    // Track total deposits in ETH
    uint256 public totalDepositedETH;

    // --- Events ---
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event BankCapReached(uint256 totalUSD);

    // --- Custom Errors ---
    error InsufficientBalance();
    error BankCapExceeded();
    error InvalidToken();

    // --- Constructor ---
    constructor(uint256 _bankCapUSD) {
        bankCapUSD = _bankCapUSD;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BANK_MANAGER_ROLE, msg.sender);
    }

    // --- Public Functions ---
    /**
     * @notice Deposit ETH or ERC20 tokens into the bank
     * @param token Address of the token, use address(0) for ETH
     * @param amount Amount to deposit
     */
    function deposit(address token, uint256 amount) external payable {
        if (token == address(0)) {
            // Deposit in ETH
            require(msg.value == amount, "Value mismatch");
            balances[msg.sender][address(0)] += amount;
            totalDepositedETH += amount;
        } else {
            // Deposit ERC20 token
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            balances[msg.sender][token] += amount;
        }

        emit Deposit(msg.sender, token, amount);
    }

    /**
     * @notice Withdraw ETH or ERC20 tokens
     * @param token Address of the token (use address(0) for ETH)
     * @param amount Amount to withdraw
     */
    function withdraw(address token, uint256 amount) external {
        uint256 balance = balances[msg.sender][token];
        if (balance < amount) revert InsufficientBalance();
        if (amount > WITHDRAW_LIMIT) revert BankCapExceeded();

        balances[msg.sender][token] -= amount;

        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }

        emit Withdraw(msg.sender, token, amount);
    }

    /**
     * @notice View balance of a user for a specific token
     */
    function balanceOf(address user, address token) external view returns (uint256) {
        return balances[user][token];
    }

    // --- Future Add-ons ---
    // Chainlink price feed integration
    // Decimal conversion utilities
    // Access-controlled parameter updates
}
