# Deployment Guide - KipuBankV3

## Prerequisites

1. **Install Foundry** (if not already installed):
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. **Get Required Information**:
   - Private key (from MetaMask or wallet)
   - Sepolia RPC URL (from Infura, Alchemy, or public RPC)
   - Etherscan API key (from etherscan.io)

## Step-by-Step Deployment

### Step 1: Setup Environment Variables

```bash
cd KipuBankV3
cp .env.example .env
```

Edit `.env` file with your values:

```env
# Your wallet private key (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# RPC URL - Choose one:
# Option 1: Infura
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID

# Option 2: Alchemy
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY

# Option 3: Public RPC (may be slower)
SEPOLIA_RPC_URL=https://rpc.sepolia.org

# Etherscan API Key (get from https://etherscan.io/myapikey)
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### Step 2: Get Testnet ETH

You need Sepolia ETH to deploy. Get it from:
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia
- https://faucet.quicknode.com/ethereum/sepolia

**Recommended**: Have at least 0.05 ETH for deployment + gas

### Step 3: Install Dependencies

```bash
make install
# or
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
```

### Step 4: Build and Test

```bash
# Build the project
make build

# Run tests to ensure everything works
make test
```

### Step 5: Deploy to Sepolia

```bash
# Load environment variables
source .env

# Deploy (this will also verify on Etherscan)
forge script script/DeploySepolia.s.sol:DeploySepoliaKipuBankV3 \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    -vvvv
```

**What happens:**
1. Contract is deployed to Sepolia
2. Automatically verified on Etherscan
3. Console shows deployed address
4. Transaction receipt is saved in `broadcast/` folder

### Step 6: Save the Contract Address

After deployment, you'll see output like:
```
KipuBankV3 deployed on Sepolia at: 0x1234567890123456789012345678901234567890
```

**Save this address!** You'll need it for the exam submission.

### Step 7: Verify Deployment (if auto-verify failed)

If automatic verification fails, verify manually:

```bash
# Set your contract address
CONTRACT_ADDRESS=0xYourContractAddressHere

# Verify
forge verify-contract $CONTRACT_ADDRESS \
    src/KipuBankV3.sol:KipuBankV3 \
    --chain-id 11155111 \
    --constructor-args $(cast abi-encode "constructor(address,address,uint256)" \
        0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008 \
        0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238 \
        1000000000000) \
    --etherscan-api-key $ETHERSCAN_API_KEY
```

### Step 8: Test Deployed Contract

```bash
# Check if contract is deployed
cast code $CONTRACT_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Check bank cap
cast call $CONTRACT_ADDRESS "bankCapUSDC()(uint256)" --rpc-url $SEPOLIA_RPC_URL

# Check USDC address
cast call $CONTRACT_ADDRESS "USDC()(address)" --rpc-url $SEPOLIA_RPC_URL
```

## Alternative: Deploy with Remix

If you prefer Remix (not recommended, but works):

### Step 1: Copy Contract to Remix

1. Go to https://remix.ethereum.org/
2. Create new file `KipuBankV3.sol`
3. Copy the entire contract from `src/KipuBankV3.sol`
4. Copy interfaces from `src/interfaces/` folder

### Step 2: Install Dependencies

In Remix:
1. Go to File Explorer
2. Create `.deps/` folder structure
3. Or use:
   ```
   npm: @openzeppelin/contracts
   ```

### Step 3: Compile

1. Go to Solidity Compiler tab
2. Select compiler version `0.8.19`
3. Enable optimization (200 runs)
4. Click "Compile KipuBankV3.sol"

### Step 4: Deploy

1. Go to Deploy & Run Transactions tab
2. Select "Injected Provider - MetaMask"
3. Switch MetaMask to Sepolia network
4. Enter constructor parameters:
   - `_uniswapRouter`: `0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008`
   - `_usdc`: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
   - `_bankCapUSDC`: `1000000000000` (1M USDC with 6 decimals)
5. Click "Deploy"
6. Confirm transaction in MetaMask

### Step 5: Verify on Etherscan (Manual)

1. Go to https://sepolia.etherscan.io/
2. Find your contract address
3. Go to "Contract" tab
4. Click "Verify and Publish"
5. Select:
   - Compiler: `v0.8.19`
   - Optimization: Yes (200 runs)
   - License: MIT
6. Paste contract code
7. Paste constructor arguments (ABI encoded)
8. Submit

## Comparison: Foundry vs Remix

| Feature | Foundry | Remix |
|---------|---------|-------|
| Speed | ⚡ Fast | 🐌 Slow |
| Testing | ✅ Built-in | ❌ Manual |
| Verification | ✅ Automatic | 🔧 Manual |
| Scripts | ✅ Reusable | ❌ One-time |
| Professional | ✅ Yes | ⚠️ Basic |
| Learning Curve | 📈 Medium | 📉 Easy |

**Recommendation**: Use Foundry for professional deployment

## Troubleshooting

### Issue: "Failed to get EIP-1559 fees"
**Solution**: Add `--legacy` flag to forge script command

### Issue: "Insufficient funds"
**Solution**: Get more Sepolia ETH from faucets

### Issue: "Verification failed"
**Solution**: Verify manually using the command in Step 7

### Issue: "Private key not found"
**Solution**: Check `.env` file and run `source .env`

### Issue: "RPC not responding"
**Solution**: Try a different RPC URL (see Step 1)

## Getting RPC URLs

### Infura (Recommended)
1. Go to https://infura.io/
2. Sign up (free)
3. Create new project
4. Copy Sepolia endpoint

### Alchemy (Recommended)
1. Go to https://www.alchemy.com/
2. Sign up (free)
3. Create new app (Ethereum Sepolia)
4. Copy HTTPS URL

### Public RPC (Backup)
- `https://rpc.sepolia.org`
- `https://ethereum-sepolia.publicnode.com`

Note: Public RPCs may be rate-limited

## Getting Etherscan API Key

1. Go to https://etherscan.io/
2. Sign up / Login
3. Go to https://etherscan.io/myapikey
4. Create new API key (free)
5. Copy the key

## Post-Deployment Checklist

- [ ] Contract deployed successfully
- [ ] Contract verified on Etherscan
- [ ] Saved contract address
- [ ] Tested basic functions (bankCapUSDC, USDC, etc.)
- [ ] Documented deployment in README
- [ ] Ready for exam submission

## For Exam Submission

You need to provide:

1. **GitHub Repository URL**:
   - Make sure all code is pushed
   - README.md is complete
   - License included

2. **Etherscan URL**:
   ```
   https://sepolia.etherscan.io/address/YOUR_CONTRACT_ADDRESS
   ```

**Example submission:**
- GitHub: https://github.com/your-username/KipuBankV3
- Etherscan: https://sepolia.etherscan.io/address/0x1234...

## Next Steps After Deployment

1. Test deposits:
```bash
# Deposit ETH
cast send $CONTRACT_ADDRESS "depositETH()" \
    --value 0.01ether \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $PRIVATE_KEY
```

2. Check balance:
```bash
cast call $CONTRACT_ADDRESS "balanceOf(address)(uint256)" \
    YOUR_WALLET_ADDRESS \
    --rpc-url $SEPOLIA_RPC_URL
```

3. Document everything in your README

---

**Need help?** Check the troubleshooting section or review the QUICKSTART.md guide.
