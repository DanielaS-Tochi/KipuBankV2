# Quick Start Guide - KipuBankV3

## 5-Minute Setup

### 1. Install Dependencies (1 min)

```bash
# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone and setup
cd KipuBankV3
```

### 2. Install Libraries (1 min)

```bash
# Install OpenZeppelin and Forge-std
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit

# Build project
forge build
```

### 3. Run Tests (1 min)

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv
```

### 4. Setup Environment (1 min)

```bash
# Copy example env
cp .env.example .env

# Edit .env with your values
nano .env
```

Add:
```env
PRIVATE_KEY=your_private_key_without_0x
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
ETHERSCAN_API_KEY=your_etherscan_key
```

### 5. Deploy to Sepolia (1 min)

```bash
# Load environment
source .env

# Deploy
forge script script/DeploySepolia.s.sol:DeploySepoliaKipuBankV3 \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify

# Note the deployed address
```

## Common Commands

### Testing
```bash
# All tests
forge test

# Specific test
forge test --match-test testDepositETH

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

### Deployment
```bash
# Sepolia
forge script script/DeploySepolia.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast

# Custom network
forge script script/Deploy.s.sol --rpc-url $YOUR_RPC --broadcast
```

### Interaction
```bash
# Check balance
cast call $CONTRACT "balanceOf(address)(uint256)" $USER_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Deposit ETH
cast send $CONTRACT "depositETH()" --value 0.01ether --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY

# Deposit USDC (approve first)
cast send $USDC "approve(address,uint256)" $CONTRACT 1000000 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
cast send $CONTRACT "depositToken(address,uint256)" $USDC 1000000 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY

# Withdraw
cast send $CONTRACT "withdraw(uint256)" 500000 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

### Verification
```bash
# Verify manually
forge verify-contract $CONTRACT \
    src/KipuBankV3.sol:KipuBankV3 \
    --chain-id 11155111 \
    --constructor-args $(cast abi-encode "constructor(address,address,uint256)" $ROUTER $USDC $CAP) \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

## Troubleshooting

### Build Fails
```bash
# Clean and rebuild
forge clean
forge build
```

### Tests Fail
```bash
# Run with max verbosity
forge test -vvvv

# Check for specific failure
forge test --match-test testName -vvvv
```

### Deployment Fails
```bash
# Check balance
cast balance $YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Check gas price
cast gas-price --rpc-url $SEPOLIA_RPC_URL

# Dry run
forge script script/DeploySepolia.s.sol --rpc-url $SEPOLIA_RPC_URL
```

## Example Workflows

### Development Workflow
```bash
# 1. Make changes to contract
vim src/KipuBankV3.sol

# 2. Run tests
forge test

# 3. Check gas
forge test --gas-report

# 4. Format code
forge fmt

# 5. Commit
git add .
git commit -m "feat: add new feature"
```

### Testing Workflow
```bash
# 1. Write test
vim test/KipuBankV3.t.sol

# 2. Run test
forge test --match-test testNewFeature -vvv

# 3. Check coverage
forge coverage

# 4. Run all tests
forge test
```

### Deployment Workflow
```bash
# 1. Test on fork
forge test --fork-url $SEPOLIA_RPC_URL

# 2. Dry run deployment
forge script script/DeploySepolia.s.sol --rpc-url $SEPOLIA_RPC_URL

# 3. Deploy
forge script script/DeploySepolia.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast

# 4. Verify
# (automatic with --verify flag)

# 5. Test deployed contract
cast call $CONTRACT "bankCapUSDC()(uint256)" --rpc-url $SEPOLIA_RPC_URL
```

## Key Addresses

### Sepolia Testnet
- **Uniswap V2 Router**: `0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008`
- **USDC**: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- **WETH**: `0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14`

### Get Testnet Tokens
- **Sepolia ETH**: https://sepoliafaucet.com/
- **Sepolia USDC**: Swap on Uniswap or use faucet

## Next Steps

1. ✅ Deploy to testnet
2. ✅ Verify contract
3. 📝 Document your deployment
4. 🧪 Test with small amounts
5. 📊 Monitor transactions
6. 🔒 Security review
7. 🚀 Deploy to mainnet (after audit)

## Resources

- **Documentation**: See README.md
- **Technical Details**: See TECHNICAL.md
- **Security**: See SECURITY.md
- **Foundry Book**: https://book.getfoundry.sh/
- **Support**: Open an issue on GitHub

---

**Happy Building! 🚀**
