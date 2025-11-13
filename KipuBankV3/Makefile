.PHONY: all test clean install build format snapshot anvil deploy verify

all: clean install build test

install:
	@echo "Installing dependencies..."
	@forge install OpenZeppelin/openzeppelin-contracts --no-commit
	@forge install foundry-rs/forge-std --no-commit

build:
	@echo "Building project..."
	@forge build

test:
	@echo "Running tests..."
	@forge test

test-v:
	@echo "Running tests with verbosity..."
	@forge test -vvv

test-gas:
	@echo "Running tests with gas report..."
	@forge test --gas-report

coverage:
	@echo "Generating coverage report..."
	@forge coverage

clean:
	@echo "Cleaning build artifacts..."
	@forge clean

format:
	@echo "Formatting code..."
	@forge fmt

snapshot:
	@echo "Creating gas snapshot..."
	@forge snapshot

anvil:
	@echo "Starting local Anvil node..."
	@anvil

deploy-sepolia:
	@echo "Deploying to Sepolia..."
	@forge script script/DeploySepolia.s.sol:DeploySepoliaKipuBankV3 \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--broadcast \
		--verify

deploy-local:
	@echo "Deploying to local Anvil..."
	@forge script script/Deploy.s.sol:DeployKipuBankV3 \
		--rpc-url http://localhost:8545 \
		--broadcast

verify:
	@echo "Verifying contract..."
	@forge script script/Verify.s.sol:VerifyKipuBankV3 \
		--rpc-url $(SEPOLIA_RPC_URL)

interact:
	@echo "Interacting with contract..."
	@forge script script/Interact.s.sol:InteractKipuBankV3 \
		--rpc-url $(SEPOLIA_RPC_URL)

help:
	@echo "Available commands:"
	@echo "  make install       - Install dependencies"
	@echo "  make build         - Build project"
	@echo "  make test          - Run tests"
	@echo "  make test-v        - Run tests with verbosity"
	@echo "  make test-gas      - Run tests with gas report"
	@echo "  make coverage      - Generate coverage report"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make format        - Format code"
	@echo "  make snapshot      - Create gas snapshot"
	@echo "  make anvil         - Start local Anvil node"
	@echo "  make deploy-sepolia - Deploy to Sepolia"
	@echo "  make deploy-local  - Deploy to local Anvil"
	@echo "  make verify        - Verify deployed contract"
	@echo "  make interact      - Interact with contract"
