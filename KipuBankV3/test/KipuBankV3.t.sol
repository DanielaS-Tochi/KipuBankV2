// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/KipuBankV3.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10**18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockUniswapV2Factory {
    mapping(address => mapping(address => address)) public pairs;

    function getPair(address tokenA, address tokenB) external view returns (address) {
        return pairs[tokenA][tokenB];
    }

    function setPair(address tokenA, address tokenB, address pair) external {
        pairs[tokenA][tokenB] = pair;
        pairs[tokenB][tokenA] = pair;
    }
}

contract MockUniswapV2Router02 {
    address public immutable WETH;
    address public immutable factory;
    mapping(address => mapping(address => uint256)) public exchangeRates;

    constructor(address _weth, address _factory) {
        WETH = _weth;
        factory = _factory;
    }

    function setExchangeRate(address tokenIn, address tokenOut, uint256 rate) external {
        exchangeRates[tokenIn][tokenOut] = rate;
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        for (uint256 i = 0; i < path.length - 1; i++) {
            uint256 rate = exchangeRates[path[i]][path[i + 1]];
            require(rate > 0, "No rate set");
            amounts[i + 1] = (amounts[i] * rate) / 1e18;
        }
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256
    ) external payable returns (uint256[] memory amounts) {
        require(path[0] == WETH, "First token must be WETH");
        amounts = this.getAmountsOut(msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output");

        MockERC20(path[path.length - 1]).mint(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256
    ) external returns (uint256[] memory amounts) {
        amounts = this.getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output");

        MockERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        MockERC20(path[path.length - 1]).mint(to, amounts[amounts.length - 1]);
    }

    receive() external payable {}
}

contract KipuBankV3Test is Test {
    KipuBankV3 public bank;
    MockUniswapV2Router02 public router;
    MockUniswapV2Factory public factory;
    MockERC20 public usdc;
    MockERC20 public weth;
    MockERC20 public dai;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    uint256 constant BANK_CAP = 1000000 * 10**6;
    uint256 constant ETH_TO_USDC_RATE = 2000 * 10**18;
    uint256 constant DAI_TO_USDC_RATE = 1 * 10**18;

    event Deposited(address indexed user, address indexed token, uint256 amountIn, uint256 usdcReceived);
    event Withdrawn(address indexed user, uint256 amount);

    function setUp() public {
        vm.startPrank(owner);

        usdc = new MockERC20("USD Coin", "USDC");
        weth = new MockERC20("Wrapped Ether", "WETH");
        dai = new MockERC20("Dai Stablecoin", "DAI");

        factory = new MockUniswapV2Factory();
        router = new MockUniswapV2Router02(address(weth), address(factory));

        factory.setPair(address(weth), address(usdc), address(0x1));
        factory.setPair(address(dai), address(usdc), address(0x2));

        router.setExchangeRate(address(weth), address(usdc), ETH_TO_USDC_RATE);
        router.setExchangeRate(address(dai), address(usdc), DAI_TO_USDC_RATE);

        bank = new KipuBankV3(address(router), address(usdc), BANK_CAP);

        usdc.mint(user1, 100000 * 10**6);
        dai.mint(user1, 100000 * 10**18);
        vm.deal(user1, 100 ether);

        usdc.mint(user2, 100000 * 10**6);
        vm.deal(user2, 100 ether);

        vm.stopPrank();
    }

    function testDepositETH() public {
        vm.startPrank(user1);

        uint256 depositAmount = 1 ether;
        uint256 expectedUSDC = (depositAmount * ETH_TO_USDC_RATE) / 1e18;
        uint256 minExpected = (expectedUSDC * 9500) / 10000;

        vm.expectEmit(true, true, false, false);
        emit Deposited(user1, address(0), depositAmount, 0);

        bank.depositETH{value: depositAmount}();

        assertGe(bank.balanceOf(user1), minExpected);
        assertEq(bank.totalDepositedUSDC(), bank.balanceOf(user1));

        vm.stopPrank();
    }

    function testDepositUSDC() public {
        vm.startPrank(user1);

        uint256 depositAmount = 1000 * 10**6;
        usdc.approve(address(bank), depositAmount);

        bank.depositToken(address(usdc), depositAmount);

        assertEq(bank.balanceOf(user1), depositAmount);
        assertEq(bank.totalDepositedUSDC(), depositAmount);

        vm.stopPrank();
    }

    function testDepositDAI() public {
        vm.startPrank(user1);

        uint256 depositAmount = 1000 * 10**18;
        uint256 expectedUSDC = (depositAmount * DAI_TO_USDC_RATE) / 1e18;
        uint256 minExpected = (expectedUSDC * 9500) / 10000;

        dai.approve(address(bank), depositAmount);
        bank.depositToken(address(dai), depositAmount);

        assertGe(bank.balanceOf(user1), minExpected);

        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user1);

        uint256 depositAmount = 1000 * 10**6;
        usdc.approve(address(bank), depositAmount);
        bank.depositToken(address(usdc), depositAmount);

        uint256 withdrawAmount = 500 * 10**6;
        bank.withdraw(withdrawAmount);

        assertEq(bank.balanceOf(user1), depositAmount - withdrawAmount);
        assertEq(usdc.balanceOf(user1), 99000 * 10**6 + withdrawAmount);

        vm.stopPrank();
    }

    function testBankCapRespected() public {
        vm.startPrank(user1);

        uint256 depositAmount = BANK_CAP + 1000 * 10**6;
        usdc.approve(address(bank), depositAmount);

        vm.expectRevert(KipuBankV3.BankCapExceeded.selector);
        bank.depositToken(address(usdc), depositAmount);

        vm.stopPrank();
    }

    function testMultipleUsersDeposit() public {
        vm.startPrank(user1);
        usdc.approve(address(bank), 50000 * 10**6);
        bank.depositToken(address(usdc), 50000 * 10**6);
        vm.stopPrank();

        vm.startPrank(user2);
        usdc.approve(address(bank), 30000 * 10**6);
        bank.depositToken(address(usdc), 30000 * 10**6);
        vm.stopPrank();

        assertEq(bank.balanceOf(user1), 50000 * 10**6);
        assertEq(bank.balanceOf(user2), 30000 * 10**6);
        assertEq(bank.totalDepositedUSDC(), 80000 * 10**6);
    }

    function testRevertInsufficientBalance() public {
        vm.startPrank(user1);

        vm.expectRevert(KipuBankV3.InsufficientBalance.selector);
        bank.withdraw(1000 * 10**6);

        vm.stopPrank();
    }

    function testRevertZeroAmount() public {
        vm.startPrank(user1);

        vm.expectRevert(KipuBankV3.ZeroAmount.selector);
        bank.depositETH{value: 0}();

        vm.stopPrank();
    }

    function testUpdateBankCap() public {
        vm.startPrank(owner);

        uint256 newCap = 2000000 * 10**6;
        bank.updateBankCap(newCap);

        assertEq(bank.bankCapUSDC(), newCap);

        vm.stopPrank();
    }

    function testGetAvailableCap() public {
        vm.startPrank(user1);

        uint256 depositAmount = 100000 * 10**6;
        usdc.approve(address(bank), depositAmount);
        bank.depositToken(address(usdc), depositAmount);

        assertEq(bank.getAvailableCap(), BANK_CAP - depositAmount);

        vm.stopPrank();
    }

    function testReceiveFunction() public {
        vm.startPrank(user1);

        uint256 depositAmount = 1 ether;
        (bool success, ) = address(bank).call{value: depositAmount}("");

        require(success, "Transfer failed");
        assertGt(bank.balanceOf(user1), 0);

        vm.stopPrank();
    }
}
