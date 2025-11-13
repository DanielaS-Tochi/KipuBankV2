// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

/**
 * @title KipuBankV3
 * @author Daniela Silvana Tochi
 * @notice Advanced DeFi banking contract that accepts any Uniswap V2 supported token,
 *         swaps it to USDC, and credits the user's balance while respecting the bank cap.
 * @dev Integrates with Uniswap V2 for automatic token swaps to USDC.
 */
contract KipuBankV3 is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant BANK_MANAGER_ROLE = keccak256("BANK_MANAGER_ROLE");

    IUniswapV2Router02 public immutable uniswapRouter;
    IUniswapV2Factory public immutable uniswapFactory;
    address public immutable USDC;
    address public immutable WETH;

    uint256 public bankCapUSDC;
    uint256 public totalDepositedUSDC;

    mapping(address => uint256) public balances;

    uint256 public constant MIN_SWAP_AMOUNT = 1000;
    uint256 public constant MAX_SLIPPAGE = 500;
    uint256 public constant SLIPPAGE_DENOMINATOR = 10000;

    event Deposited(address indexed user, address indexed token, uint256 amountIn, uint256 usdcReceived);
    event Withdrawn(address indexed user, uint256 amount);
    event BankCapUpdated(uint256 newCap);
    event TokenSwapped(address indexed token, uint256 amountIn, uint256 usdcOut);

    error InsufficientBalance();
    error BankCapExceeded();
    error InvalidToken();
    error SwapFailed();
    error ZeroAmount();
    error NoLiquidity();

    constructor(
        address _uniswapRouter,
        address _usdc,
        uint256 _bankCapUSDC
    ) {
        require(_uniswapRouter != address(0), "Invalid router");
        require(_usdc != address(0), "Invalid USDC");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BANK_MANAGER_ROLE, msg.sender);

        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        USDC = _usdc;
        WETH = IUniswapV2Router02(_uniswapRouter).WETH();
        uniswapFactory = IUniswapV2Factory(IUniswapV2Router02(_uniswapRouter).factory());
        bankCapUSDC = _bankCapUSDC;
    }

    function depositETH() external payable nonReentrant {
        if (msg.value == 0) revert ZeroAmount();

        uint256 usdcAmount = _swapETHToUSDC(msg.value);

        if (totalDepositedUSDC + usdcAmount > bankCapUSDC) revert BankCapExceeded();

        balances[msg.sender] += usdcAmount;
        totalDepositedUSDC += usdcAmount;

        emit Deposited(msg.sender, address(0), msg.value, usdcAmount);
    }

    function depositToken(address token, uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (token == address(0)) revert InvalidToken();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        uint256 usdcAmount;

        if (token == USDC) {
            usdcAmount = amount;
        } else {
            usdcAmount = _swapTokenToUSDC(token, amount);
        }

        if (totalDepositedUSDC + usdcAmount > bankCapUSDC) revert BankCapExceeded();

        balances[msg.sender] += usdcAmount;
        totalDepositedUSDC += usdcAmount;

        emit Deposited(msg.sender, token, amount, usdcAmount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount;
        totalDepositedUSDC -= amount;

        IERC20(USDC).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function updateBankCap(uint256 newCap) external onlyRole(BANK_MANAGER_ROLE) {
        bankCapUSDC = newCap;
        emit BankCapUpdated(newCap);
    }

    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    function getAvailableCap() external view returns (uint256) {
        return bankCapUSDC > totalDepositedUSDC ? bankCapUSDC - totalDepositedUSDC : 0;
    }

    function _swapETHToUSDC(uint256 ethAmount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        _validatePair(WETH, USDC);

        uint256[] memory amounts = uniswapRouter.getAmountsOut(ethAmount, path);
        uint256 minAmountOut = (amounts[1] * (SLIPPAGE_DENOMINATOR - MAX_SLIPPAGE)) / SLIPPAGE_DENOMINATOR;

        uint256[] memory swappedAmounts = uniswapRouter.swapExactETHForTokens{value: ethAmount}(
            minAmountOut,
            path,
            address(this),
            block.timestamp + 300
        );

        emit TokenSwapped(address(0), ethAmount, swappedAmounts[1]);
        return swappedAmounts[1];
    }

    function _swapTokenToUSDC(address token, uint256 amount) internal returns (uint256) {
        IERC20(token).safeApprove(address(uniswapRouter), amount);

        address[] memory path;

        if (_pairExists(token, USDC)) {
            path = new address[](2);
            path[0] = token;
            path[1] = USDC;
        } else if (_pairExists(token, WETH) && _pairExists(WETH, USDC)) {
            path = new address[](3);
            path[0] = token;
            path[1] = WETH;
            path[2] = USDC;
        } else {
            revert NoLiquidity();
        }

        uint256[] memory amounts = uniswapRouter.getAmountsOut(amount, path);
        uint256 minAmountOut = (amounts[amounts.length - 1] * (SLIPPAGE_DENOMINATOR - MAX_SLIPPAGE)) / SLIPPAGE_DENOMINATOR;

        uint256[] memory swappedAmounts = uniswapRouter.swapExactTokensForTokens(
            amount,
            minAmountOut,
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 usdcReceived = swappedAmounts[swappedAmounts.length - 1];
        emit TokenSwapped(token, amount, usdcReceived);

        return usdcReceived;
    }

    function _pairExists(address tokenA, address tokenB) internal view returns (bool) {
        address pair = uniswapFactory.getPair(tokenA, tokenB);
        return pair != address(0);
    }

    function _validatePair(address tokenA, address tokenB) internal view {
        if (!_pairExists(tokenA, tokenB)) revert NoLiquidity();
    }

    receive() external payable {
        if (msg.value == 0) revert ZeroAmount();

        uint256 usdcAmount = _swapETHToUSDC(msg.value);

        if (totalDepositedUSDC + usdcAmount > bankCapUSDC) revert BankCapExceeded();

        balances[msg.sender] += usdcAmount;
        totalDepositedUSDC += usdcAmount;

        emit Deposited(msg.sender, address(0), msg.value, usdcAmount);
    }
}
