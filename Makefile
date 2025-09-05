# Chainlink CCIP Vault Makefile
# A comprehensive development automation tool for Chainlink CCIP vault system

# Load environment variables from .env file
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

.PHONY: help dev-setup dev-test dev-deploy-local test test-verbose test-coverage test-gas test-match format format-check lint deploy-local deploy-source deploy-destination anvil anvil-fork-sepolia size size-contracts clean install build setup-env verify-sepolia verify-base-sepolia docs security benchmark console git-hooks

# Default target
help:
	@echo "Cross-Chain Vault System - Development Commands"
	@echo "================================================"
	@echo ""
	@echo "Development Workflow:"
	@echo "  dev-setup          Complete development setup (env, install, build)"
	@echo "  dev-test           Build and run tests"
	@echo "  dev-deploy-local   Complete local development workflow"
	@echo ""
	@echo "Testing:"
	@echo "  test               Run all tests"
	@echo "  test-verbose       Run tests with verbose output"
	@echo "  test-coverage      Run tests with coverage report"
	@echo "  test-gas           Run tests with gas reporting"
	@echo "  test-match MATCH=  Run specific test (e.g., MATCH=testCrossChainDeposit)"
	@echo ""
	@echo "Code Quality:"
	@echo "  format             Format all Solidity files"
	@echo "  format-check       Check code formatting"
	@echo "  lint               Run linter checks"
	@echo ""
	@echo "Deployment:"
	@echo "  deploy-local       Deploy to local Anvil network (using script)"
	@echo "  deploy-source      Deploy source chain contracts (Usage: make deploy-source RPC_URL=<url>)"
	@echo "  deploy-destination Deploy destination chain contracts (Usage: make deploy-destination RPC_URL=<url>)"
	@echo ""
	@echo "Local Development:"
	@echo "  anvil              Start local Anvil instance"
	@echo "  anvil-fork-sepolia Start Anvil forked from Sepolia"
	@echo ""
	@echo "Analysis:"
	@echo "  size               Show contract sizes"
	@echo "  size-contracts     Show detailed contract sizes"
	@echo ""
	@echo "Utilities:"
	@echo "  clean              Clean build artifacts"
	@echo "  install            Install dependencies"
	@echo "  build              Build contracts"

# Installation commands
install:
	@echo "Installing dependencies..."
	forge install smartcontractkit/chainlink-local
	forge install OpenZeppelin/openzeppelin-contracts

# Development workflow commands
dev-setup: install build
	@echo "Development setup complete!"

dev-test: build test
	@echo "Development test complete!"

dev-deploy-local: build anvil deploy-local
	@echo "Local development deployment complete!"

# Testing commands
test:
	@echo "Running tests..."
	forge test

test-verbose:
	@echo "Running tests with verbose output..."
	forge test -vvvv

test-coverage:
	@echo "Running tests with coverage..."
	forge coverage

test-gas:
	@echo "Running tests with gas reporting..."
	forge test --gas-report

test-match:
	@echo "Running tests matching: $(MATCH)"
	forge test --match-test $(MATCH) -vvvv

# Code quality commands
format:
	@echo "Formatting code..."
	forge fmt

format-check:
	@echo "Checking code formatting..."
	forge fmt --check

lint:
	@echo "Running linter checks..."
	solhint 'src/**/*.sol' 'test/**/*.sol'
	@echo "Running Solhint..."

# Deployment commands
deploy-local:
	@echo "Deploying to local network..."
	@echo "Note: Make sure Anvil is running on http://localhost:8545"
	@echo "Note: Set PRIVATE_KEY in your environment or .env file"
	@if [ -z "$(PRIVATE_KEY)" ]; then \
		echo "Using default Anvil private key..."; \
		PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 forge script script/DeployLocal.s.sol --rpc-url http://localhost:8545 --broadcast -vvvv; \
	else \
		echo "Using provided PRIVATE_KEY..."; \
		forge script script/DeployLocal.s.sol --rpc-url http://localhost:8545 --broadcast -vvvv; \
	fi
	@echo "Local deployment complete!"


deploy-source:
	@echo "Deploying source chain contracts..."
	@if [ -z "$(RPC_URL)" ]; then \
		echo "Error: RPC_URL is not set. Please provide it as an argument:"; \
		echo "  make deploy-source RPC_URL=<your-rpc-url>"; \
		echo ""; \
		echo "Example:"; \
		echo "  make deploy-source RPC_URL=https://sepolia.infura.io/v3/YOUR-PROJECT-ID"; \
		exit 1; \
	fi
	@echo "Deploying SenderVault..."
	forge script script/DeploySenderVault.s.sol \
		--rpc-url $(RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		-vvvv

deploy-destination:
	@echo "Deploying destination chain contracts..."
	@if [ -z "$(RPC_URL)" ]; then \
		echo "Error: RPC_URL is not set. Please provide it as an argument:"; \
		echo "  make deploy-destination RPC_URL=<your-rpc-url>"; \
		echo ""; \
		echo "Example:"; \
		echo "  make deploy-destination RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR-API-KEY"; \
		exit 1; \
	fi
	@echo "Deploying ReceiverVault and CCIPTransporter..."
	forge script script/DeployDestination.s.sol \
		--rpc-url $(RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast \
		--verify \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		-vvvv

# Local development commands
anvil:
	@echo "Starting local Anvil instance..."
	anvil --host 0.0.0.0 --port 8545

anvil-fork-sepolia:
	@echo "Starting Anvil forked from Sepolia..."
	@if [ -z "$(SEPOLIA_RPC_URL)" ]; then echo "Error: SEPOLIA_RPC_URL not set"; exit 1; fi
	anvil --host 0.0.0.0 --port 8545 --fork-url $(SEPOLIA_RPC_URL)

# Analysis commands
size:
	@echo "Contract sizes:"
	forge build --sizes

size-contracts:
	@echo "Detailed contract sizes:"
	forge build --sizes --contracts

# Utility commands
clean:
	@echo "Cleaning build artifacts..."
	forge clean
	rm -rf cache out

build: install
	@echo "Building contracts..."
	forge build

# Environment setup helper
setup-env:
	@echo "Setting up environment..."
	@if [ ! -f .env ]; then \
		echo "Creating .env file..."; \
		echo "# Network RPC URLs" > .env; \
		echo "SEPOLIA_RPC_URL=\"your-sepolia-rpc-url\"" >> .env; \
		echo "BASE_SEPOLIA_RPC_URL=\"your-base-sepolia-rpc-url\"" >> .env; \
		echo "" >> .env; \
		echo "# Private Keystore (for deployment)" >> .env; \
		echo "ACCOUNT=\"your-account-name\"" >> .env; \
		echo "PRIVATE_KEY=\"your-private-key\"" >> .env; \
		echo "" >> .env; \
		echo "# API Keys (for contract verification)" >> .env; \
		echo "ETHERSCAN_API_KEY=\"your-etherscan-api-key\"" >> .env; \
		echo "BASESCAN_API_KEY=\"your-basescan-api-key\"" >> .env; \
		echo ".env file created. Please update with your actual values."; \
	else \
		echo ".env file already exists."; \
	fi

# Verification commands
verify-sepolia:
	@echo "Verifying contracts on Sepolia..."
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then echo "Error: ETHERSCAN_API_KEY not set"; exit 1; fi
	@if [ -z "$(CONTRACT_ADDRESS)" ]; then echo "Error: CONTRACT_ADDRESS not set. Usage: make verify-sepolia CONTRACT_ADDRESS=0x..."; exit 1; fi
	forge verify-contract $(CONTRACT_ADDRESS) src/SenderVault.sol:SenderVault --chain-id 11155111 --etherscan-api-key $(ETHERSCAN_API_KEY)

verify-base-sepolia:
	@echo "Verifying contracts on Base Sepolia..."
	@if [ -z "$(BASESCAN_API_KEY)" ]; then echo "Error: BASESCAN_API_KEY not set"; exit 1; fi
	@if [ -z "$(CONTRACT_ADDRESS)" ]; then echo "Error: CONTRACT_ADDRESS not set. Usage: make verify-base-sepolia CONTRACT_ADDRESS=0x..."; exit 1; fi
	@echo "Which contract to verify?"
	@echo "1) ReceiverVault"
	@echo "2) CCIPTransporter"
	@read -p "Enter choice (1-2): " choice; \
	case $$choice in \
		1) contract="src/ReceiverVault.sol:ReceiverVault";; \
		2) contract="src/CCIPTransporter.sol:CCIPTransporter";; \
		*) echo "Invalid choice"; exit 1;; \
	esac; \
	forge verify-contract $(CONTRACT_ADDRESS) $$contract --chain-id 84532 --etherscan-api-key $(BASESCAN_API_KEY)

# Documentation
docs:
	@echo "Generating documentation..."
	forge doc
	@echo "Documentation generated in docs/"

# Security checks
security:
	@echo "Running security checks..."
	@echo "Running Slither analysis..."
	slither . || true
	@echo "Running Mythril analysis..."
	myth analyze src/*.sol || true

# Performance testing
benchmark:
	@echo "Running performance benchmarks..."
	forge test --gas-report --match-test "test.*Gas"

# Interactive commands
console:
	@echo "Starting Forge console..."
	forge console

# Git helpers
git-hooks:
	@echo "Setting up git hooks..."
	@if [ -d .git ]; then \
		echo "#!/bin/sh" > .git/hooks/pre-commit; \
		echo "make format-check" >> .git/hooks/pre-commit; \
		echo "make test" >> .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "Git hooks installed."; \
	else \
		echo "Not a git repository."; \
	fi
