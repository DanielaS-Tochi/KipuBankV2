# Technical Documentation - KipuBankV3

## Architecture Overview

KipuBankV3 is built on three core principles:
1. **Composability**: Integrates seamlessly with Uniswap V2
2. **Security**: Multiple layers of protection
3. **Efficiency**: Optimized for gas and capital efficiency

## Contract Structure

```
KipuBankV3
│
├─ Inheritance
│  ├─ AccessControl (OpenZeppelin)
│  └─ ReentrancyGuard (OpenZeppelin)
│
├─ State Variables
│  ├─ Immutable
│  │  ├─ uniswapRouter
│  │  ├─ uniswapFactory
│  │  ├─ USDC
│  │  └─ WETH
│  │
│  └─ Mutable
│     ├─ bankCapUSDC
│     ├─ totalDepositedUSDC
│     └─ balances (mapping)
│
├─ External Functions
│  ├─ depositETH()
│  ├─ depositToken()
│  ├─ withdraw()
│  └─ updateBankCap()
│
└─ Internal Functions
   ├─ _swapETHToUSDC()
   ├─ _swapTokenToUSDC()
   ├─ _pairExists()
   └─ _validatePair()
```

## State Variables

### Immutable Variables

```solidity
IUniswapV2Router02 public immutable uniswapRouter;
IUniswapV2Factory public immutable uniswapFactory;
address public immutable USDC;
address public immutable WETH;
```

**Benefits**:
- Gas optimization: ~2100 gas saved per read
- Security: Cannot be changed after deployment
- Predictability: Users know these won't change

### Storage Layout

```
Slot 0: AccessControl inherited storage
Slot 1: ReentrancyGuard._status
Slot 2: bankCapUSDC (uint256)
Slot 3: totalDepositedUSDC (uint256)
Slot 4+: balances mapping
```

## Function Analysis

### depositETH()

**Signature**: `function depositETH() external payable nonReentrant`

**Flow**:
```
1. Validate msg.value > 0
2. Swap ETH → USDC via Uniswap
3. Check bank cap
4. Update user balance
5. Update total deposited
6. Emit event
```

**Gas Cost**: ~150,000 gas

**Considerations**:
- Uses `msg.value`, no token approval needed
- Automatically wrapped to WETH by router
- Slippage protected

### depositToken()

**Signature**: `function depositToken(address token, uint256 amount) external nonReentrant`

**Flow**:
```
1. Validate inputs
2. Transfer token from user
3. If token == USDC:
   - Skip swap
   - Use amount directly
4. Else:
   - Approve router
   - Determine swap path
   - Execute swap
5. Check bank cap
6. Update balances
7. Emit event
```

**Path Selection Logic**:
```solidity
if (_pairExists(token, USDC)) {
    path = [token, USDC]
} else if (_pairExists(token, WETH) && _pairExists(WETH, USDC)) {
    path = [token, WETH, USDC]
} else {
    revert NoLiquidity()
}
```

**Gas Cost**:
- USDC: ~80,000 gas
- Token (direct): ~200,000 gas
- Token (via WETH): ~280,000 gas

### withdraw()

**Signature**: `function withdraw(uint256 amount) external nonReentrant`

**Flow**:
```
1. Validate amount > 0
2. Check user balance
3. Decrease user balance
4. Decrease total deposited
5. Transfer USDC to user
6. Emit event
```

**Gas Cost**: ~60,000 gas

**Security**:
- Checks-Effects-Interactions pattern
- ReentrancyGuard protection
- SafeERC20 transfer

## Swap Mechanisms

### Direct Swap (Token → USDC)

```solidity
path = [tokenIn, USDC]
```

**Example**: DAI → USDC

**Advantages**:
- Lower gas cost
- Better price (fewer hops)
- Lower slippage

### Indirect Swap (Token → WETH → USDC)

```solidity
path = [tokenIn, WETH, USDC]
```

**Example**: LINK → WETH → USDC

**Advantages**:
- Access to more tokens
- WETH is highly liquid

**Trade-offs**:
- Higher gas cost (~40% more)
- More slippage potential
- Two pool fees instead of one

## Slippage Protection

### Implementation

```solidity
uint256 public constant MAX_SLIPPAGE = 500; // 5%
uint256 public constant SLIPPAGE_DENOMINATOR = 10000;

uint256 minAmountOut = (expectedAmount * (SLIPPAGE_DENOMINATOR - MAX_SLIPPAGE)) / SLIPPAGE_DENOMINATOR;
```

### Examples

| Expected Output | Min Output (5% slippage) |
|----------------|-------------------------|
| 1000 USDC      | 950 USDC               |
| 500 USDC       | 475 USDC               |
| 100 USDC       | 95 USDC                |

### Rationale

**Why 5%?**
- Balanced protection
- Allows for market volatility
- Prevents most sandwich attacks
- Still executes in volatile markets

**Trade-offs**:
- Too low: Transactions may fail
- Too high: Users may overpay

## Bank Cap Mechanism

### Purpose
Limits total USDC in the contract to manage risk.

### Implementation

```solidity
if (totalDepositedUSDC + usdcAmount > bankCapUSDC) {
    revert BankCapExceeded();
}
```

### Checking Available Capacity

```solidity
function getAvailableCap() external view returns (uint256) {
    return bankCapUSDC > totalDepositedUSDC
        ? bankCapUSDC - totalDepositedUSDC
        : 0;
}
```

### Use Cases

1. **Risk Management**: Limit exposure
2. **Testing**: Gradual rollout
3. **Regulatory**: Compliance requirements
4. **Liquidity**: Match available liquidity

## Access Control

### Roles

```solidity
bytes32 public constant BANK_MANAGER_ROLE = keccak256("BANK_MANAGER_ROLE");
```

### Role Hierarchy

```
DEFAULT_ADMIN_ROLE (deployer)
    │
    ├─ Can grant/revoke all roles
    ├─ Can update bank cap
    └─ Full control

BANK_MANAGER_ROLE
    │
    └─ Can update bank cap
```

### Best Practices

1. **Deployer**: Should be multi-sig
2. **Manager**: Can be EOA or contract
3. **Rotation**: Regularly rotate keys
4. **Monitoring**: Monitor role changes

## Error Handling

### Custom Errors

```solidity
error InsufficientBalance();
error BankCapExceeded();
error InvalidToken();
error SwapFailed();
error ZeroAmount();
error NoLiquidity();
```

**Advantages**:
- Gas efficient (~99 bytes vs ~200+ for strings)
- Type-safe
- Clear semantics

### Error Examples

```solidity
// Bad (expensive)
require(amount > 0, "Amount must be greater than zero");

// Good (cheap)
if (amount == 0) revert ZeroAmount();
```

## Events

### Deposited Event

```solidity
event Deposited(
    address indexed user,
    address indexed token,
    uint256 amountIn,
    uint256 usdcReceived
);
```

**Use Cases**:
- Track deposits
- Calculate swap rates
- User notifications
- Analytics

### Withdrawn Event

```solidity
event Withdrawn(
    address indexed user,
    uint256 amount
);
```

### TokenSwapped Event

```solidity
event TokenSwapped(
    address indexed token,
    uint256 amountIn,
    uint256 usdcOut
);
```

**Use Cases**:
- Audit swap rates
- Detect unusual activity
- Price tracking

## Gas Optimization Techniques

### 1. Immutable Variables
**Savings**: ~2100 gas per read
```solidity
address public immutable USDC;
```

### 2. Custom Errors
**Savings**: ~100+ gas per revert
```solidity
error ZeroAmount();
if (amount == 0) revert ZeroAmount();
```

### 3. Short-circuit Evaluation
```solidity
// Check cheapest condition first
if (token == USDC) {
    // Skip expensive swap
}
```

### 4. Unchecked Arithmetic (Future)
```solidity
unchecked {
    // Safe after explicit check
    balances[user] -= amount;
}
```

### 5. Calldata vs Memory
```solidity
// Use calldata for read-only arrays
function swap(address[] calldata path) external
```

## Testing Strategy

### Unit Tests
- Individual function testing
- Edge cases
- Error conditions

### Integration Tests
- Multi-user scenarios
- Complex swap paths
- Bank cap enforcement

### Fuzz Tests (Recommended)
```solidity
function testFuzz_Deposit(uint256 amount) public {
    vm.assume(amount > 0 && amount < type(uint128).max);
    // Test logic
}
```

### Invariant Tests (Recommended)
```solidity
function invariant_TotalBalancesMatchesDeposited() public {
    assertEq(
        getTotalBalances(),
        bank.totalDepositedUSDC()
    );
}
```

## Deployment Checklist

### Pre-Deployment
- [ ] All tests pass
- [ ] Gas optimization review
- [ ] Security review
- [ ] Verify constructor parameters
- [ ] Check network (testnet/mainnet)

### Deployment
- [ ] Deploy contract
- [ ] Verify on Etherscan
- [ ] Check immutable variables
- [ ] Grant roles if needed
- [ ] Set initial bank cap

### Post-Deployment
- [ ] Test with small amounts
- [ ] Verify all functions
- [ ] Monitor events
- [ ] Document addresses
- [ ] Announce to users

## Upgrade Path

KipuBankV3 is **not upgradeable** by design.

**Reasons**:
1. Simpler security model
2. Users trust immutability
3. No proxy risk
4. Lower gas costs

**Future Upgrades**:
- Deploy new version
- Allow migration
- Deprecate old version

## Integration Guide

### For Frontend Developers

```javascript
// Initialize contract
const bank = new ethers.Contract(address, abi, signer);

// Deposit ETH
await bank.depositETH({ value: ethers.parseEther("1") });

// Deposit Token
await token.approve(bankAddress, amount);
await bank.depositToken(tokenAddress, amount);

// Check balance
const balance = await bank.balanceOf(userAddress);

// Withdraw
await bank.withdraw(amount);
```

### For Smart Contract Developers

```solidity
// Import interface
import "./interfaces/IKipuBankV3.sol";

// Use in your contract
IKipuBankV3 bank = IKipuBankV3(bankAddress);
bank.depositToken{value: msg.value}(tokenAddress, amount);
```

## Performance Metrics

### Transaction Costs

| Operation | Gas Cost | USD (50 gwei) |
|-----------|----------|---------------|
| Deploy | ~2,500,000 | ~$125 |
| Deposit ETH | ~150,000 | ~$7.50 |
| Deposit USDC | ~80,000 | ~$4.00 |
| Deposit Token | ~200,000 | ~$10.00 |
| Withdraw | ~60,000 | ~$3.00 |

### Storage Costs

| Variable | Size | Cost per write |
|----------|------|----------------|
| balance | 32 bytes | ~20,000 gas |
| bankCap | 32 bytes | ~20,000 gas |
| totalDeposited | 32 bytes | ~20,000 gas |

## Comparison with V2

| Feature | V2 | V3 |
|---------|----|----|
| Token Support | ETH, USDC | Any ERC20 |
| Swap Integration | None | Uniswap V2 |
| Oracle | Chainlink | Uniswap Spot |
| Gas Cost | Lower | Higher |
| Flexibility | Low | High |
| Complexity | Low | Medium |

## Future Improvements

### Version 3.1
1. **Uniswap V3**: Better capital efficiency
2. **Chainlink Oracles**: Better price feeds
3. **User Slippage**: Customizable slippage
4. **Batch Operations**: Multiple deposits in one tx

### Version 3.2
1. **Cross-chain**: Bridges to L2s
2. **Yield Strategies**: Auto-compounding
3. **Limit Orders**: Time-delayed swaps
4. **NFT Receipts**: Deposit NFTs

## Resources

- [Uniswap V2 Docs](https://docs.uniswap.org/contracts/v2/overview)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Ethereum Gas Optimization](https://gist.github.com/hrkrshnn/ee8fabd532058307229d65dcd5836ddc)

---

**Document Version**: 1.0.0
**Last Updated**: 2025-11-13
**Maintainer**: Daniela Silvana Tochi
