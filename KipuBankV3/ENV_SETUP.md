# .env Setup Guide

## Quick Setup (2 minutes)

### Step 1: Create .env file
```bash
cd KipuBankV3
cp .env.example .env
```

### Step 2: Get Your Private Key from MetaMask

1. Open MetaMask
2. Click the 3 dots menu
3. Select "Account Details"
4. Click "Show Private Key"
5. Enter your password
6. Copy the private key (without 0x prefix)

**⚠️ IMPORTANT**: Never share your private key!

### Step 3: Get Free RPC URL

#### Option A: Infura (Recommended)
1. Go to https://infura.io/
2. Sign up (free)
3. Create "New Key" → Select "Web3 API"
4. Copy the Sepolia endpoint URL

   Example: `https://sepolia.infura.io/v3/abc123def456...`

#### Option B: Alchemy (Also Great)
1. Go to https://www.alchemy.com/
2. Sign up (free)
3. Create "New App" → Chain: "Ethereum", Network: "Sepolia"
4. Copy the HTTPS URL

   Example: `https://eth-sepolia.g.alchemy.com/v2/abc123def456...`

#### Option C: Public RPC (No signup needed)
Use: `https://rpc.sepolia.org`

**Note**: Public RPCs may be slower and rate-limited

### Step 4: Get Etherscan API Key

1. Go to https://etherscan.io/
2. Sign up (free)
3. Go to https://etherscan.io/myapikey
4. Click "Add" to create new API key
5. Copy the key

### Step 5: Fill in .env

Edit your `.env` file:

```env
# Your private key (REMOVE the 0x prefix if it has one)
PRIVATE_KEY=1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

# RPC URL (paste what you got from Infura/Alchemy)
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID

# Etherscan API key
ETHERSCAN_API_KEY=ABC123DEF456GHI789

# Optional: For custom deployments (already set in DeploySepolia.s.sol)
UNISWAP_ROUTER=0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
USDC_ADDRESS=0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
BANK_CAP_USDC=1000000000000
```

### Step 6: Verify Setup

```bash
# Load environment variables
source .env

# Test RPC connection
cast block-number --rpc-url $SEPOLIA_RPC_URL

# Check your wallet balance
cast balance YOUR_WALLET_ADDRESS --rpc-url $SEPOLIA_RPC_URL
```

If both commands work, you're ready to deploy!

## Complete .env Template

```env
# ============================================
# REQUIRED FOR DEPLOYMENT
# ============================================

# Private Key (without 0x prefix)
# Get from: MetaMask → Account Details → Show Private Key
PRIVATE_KEY=your_private_key_here

# Sepolia RPC URL
# Get from: Infura or Alchemy (free signup)
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID

# Etherscan API Key
# Get from: https://etherscan.io/myapikey
ETHERSCAN_API_KEY=your_etherscan_api_key

# ============================================
# OPTIONAL (for mainnet or custom networks)
# ============================================

# Mainnet RPC URL (if deploying to mainnet)
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID

# Contract address (after deployment, for interaction)
CONTRACT_ADDRESS=0xYourContractAddressAfterDeployment

# Custom deployment parameters (optional)
UNISWAP_ROUTER=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
USDC_ADDRESS=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
BANK_CAP_USDC=1000000000000
```

## Common Issues

### ❌ "Private key not found"
**Fix**:
```bash
# Make sure to source the .env file
source .env

# Verify it's loaded
echo $PRIVATE_KEY
```

### ❌ "Insufficient funds for gas"
**Fix**: Get Sepolia ETH from faucets:
- https://sepoliafaucet.com/
- https://www.alchemy.com/faucets/ethereum-sepolia

### ❌ "Failed to get EIP-1559 fees"
**Fix**: Add `--legacy` flag to deployment command

### ❌ "RPC URL not responding"
**Fix**:
1. Check if URL is correct
2. Try a different RPC provider
3. Use public RPC as backup: `https://rpc.sepolia.org`

## Security Best Practices

### ✅ DO:
- Keep your private key secret
- Use `.gitignore` to exclude `.env`
- Use different keys for testnet and mainnet
- Back up your private key securely

### ❌ DON'T:
- Commit `.env` to GitHub
- Share your private key
- Use mainnet keys on testnet
- Store keys in plain text publicly

## Quick Reference

| Service | Purpose | Free Tier | URL |
|---------|---------|-----------|-----|
| Infura | RPC Provider | ✅ Yes | https://infura.io |
| Alchemy | RPC Provider | ✅ Yes | https://alchemy.com |
| Etherscan | Block Explorer | ✅ Yes | https://etherscan.io |
| Sepolia Faucet | Get Test ETH | ✅ Yes | https://sepoliafaucet.com |

## After Setup

Once your `.env` is configured, you can:

1. **Deploy**:
```bash
make deploy-sepolia
```

2. **Verify** (if needed):
```bash
make verify
```

3. **Interact**:
```bash
cast call $CONTRACT_ADDRESS "bankCapUSDC()(uint256)" --rpc-url $SEPOLIA_RPC_URL
```

## Need Help?

- Check `DEPLOYMENT_GUIDE.md` for full deployment instructions
- Check `QUICKSTART.md` for quick commands
- Check `README.md` for project overview

---

**Ready to deploy?** Run: `make deploy-sepolia`
