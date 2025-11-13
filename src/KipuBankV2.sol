// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title KipuBankV2
 * @author Daniela Silvana Tochi
 * @notice Upgraded version of KipuBank with multi-token support, Chainlink oracle integration,
 *         role-based access control, and improved accounting and security.
 */
contract KipuBankV2 is AccessControl, ReentrancyGuard {
    // --- Roles ---
    bytes32 public constant BANK_MANAGER_ROLE = keccak256("BANK_MANAGER_ROLE");

    // --- Oracle (ETH/USD Chainlink) ---
    AggregatorV3Interface public immutable priceFeed;
    uint8 public constant USDC_DECIMALS = 6; // standard for accounting

    // --- Bank Parameters ---
    uint256 public bankCapUSD; // Maximum USD value allowed in the bank
    uint256 public totalDepositedUSD;

    // --- Internal Accounting ---
    mapping(address => mapping(address => uint256)) public balances;

    // --- Events ---
    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event BankCapUpdated(uint256 newCap);

    // --- Custom Errors ---
    error InsufficientBalance();
    error BankCapExceeded();

    // --- Constructor ---
    constructor(address _priceFeed, uint256 _bankCapUSD) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BANK_MANAGER_ROLE, msg.sender);
        priceFeed = AggregatorV3Interface(_priceFeed);
        bankCapUSD = _bankCapUSD;
    }

    // --- Deposit Functions ---
    function depositETH() public payable nonReentrant {
        uint256 valueUSD = _convertETHToUSD(msg.value);
        if (totalDepositedUSD + valueUSD > bankCapUSD) revert BankCapExceeded();

        balances[msg.sender][address(0)] += msg.value;
        totalDepositedUSD += valueUSD;

        emit Deposited(msg.sender, address(0), msg.value);
    }

    function depositToken(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 valueUSD = _convertToUSDCDecimals(token, amount);
        if (totalDepositedUSD + valueUSD > bankCapUSD) revert BankCapExceeded();

        balances[msg.sender][token] += amount;
        totalDepositedUSD += valueUSD;

        emit Deposited(msg.sender, token, amount);
    }

    // --- Withdraw Functions ---
    function withdrawETH(uint256 amount) external nonReentrant {
        if (balances[msg.sender][address(0)] < amount) revert InsufficientBalance();

        balances[msg.sender][address(0)] -= amount;
        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, address(0), amount);
    }

    function withdrawToken(address token, uint256 amount) external nonReentrant {
        if (balances[msg.sender][token] < amount) revert InsufficientBalance();

        balances[msg.sender][token] -= amount;
        IERC20(token).transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, token, amount);
    }

    // --- Admin Functions ---
    function updateBankCap(uint256 newCap) external onlyRole(BANK_MANAGER_ROLE) {
        bankCapUSD = newCap;
        emit BankCapUpdated(newCap);
    }

    // --- Internal Utility Functions ---
    function _convertETHToUSD(uint256 ethAmount) internal view returns (uint256) {
        (, int256 price,,,) = priceFeed.latestRoundData(); // ETH/USD with 8 decimals
        require(price > 0, "Invalid price feed");
        uint256 ethUSD = (ethAmount * uint256(price)) / 1e8;
        return ethUSD / (10 ** (18 - USDC_DECIMALS));
    }

    function _convertToUSDCDecimals(address, uint256 tokenAmount) internal pure returns (uint256) {
        // Simplified assumption: tokens have 18 decimals
        return tokenAmount / (10 ** (18 - USDC_DECIMALS));
    }

    // --- Fallback ---
    receive() external payable {
        depositETH();
    }
}

