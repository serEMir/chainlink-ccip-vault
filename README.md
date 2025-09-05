# Cross Chain Vault system (powered by chainlink CCIP)

A decentralized cross-chain vault system that enables users to deposit and withdraw tokens across different blockchain networks using Chainlink's Cross-Chain Interoperability Protocol (CCIP).

## Table of Contents
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Contract Overview](#contract-overview)
- [Available Commands](#available-commands)
- [Configuration](#configuration)
- [Security Features](#security-features)
- [Dependencies](#dependencies)

## Quick Start

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone the repository
git clone https://github.com/serEMir/chainlink-ccip-vault.git
cd chainlink-ccip-vault

# Install dependencies and build
make dev-setup

# Configure environment
make setup-env        # Creates .env template
```

## Project Structure
```
chainlink-ccip-vault/
├── src/                    # Smart contract source files
│   ├── CCIPTransporter.sol # CCIP message handling
│   ├── ReceiverVault.sol   # Destination chain vault
│   ├── SenderVault.sol     # Source chain vault
│   ├── interfaces/         # Contract interfaces
│   └── mocks/             # Mock contracts for testing
├── script/                 # Deployment scripts
├── test/                   # Test files
├── foundry.toml           # Foundry configuration
└── Makefile              # Build & deployment automation
```

## Contract Overview

### Core Contracts

1. **SenderVault.sol**
   - Source chain entry point
   - Handles initial deposit requests
   - Initiates cross-chain transfers
   - Manages withdrawal requests
   - CCIP fee handling in LINK tokens

2. **ReceiverVault.sol**
   - Destination chain vault
   - Stores actual token balances
   - Processes cross-chain deposits
   - Handles withdrawal executions
   - Maintains user token balances

3. **CCIPTransporter.sol**
   - CCIP message handler
   - Manages cross-chain communication
   - Validates messages and token transfers
   - Ensures secure message routing
   - Token mapping management

### Deployment Scripts

1. **DeployLocal.s.sol**
   - Local development deployment
   - Sets up complete system for testing

2. **DeploySenderVault.s.sol**
   - Deploys source chain components (Sepolia)
   - Configures CCIP router and token mappings

3. **DeployDestination.s.sol**
   - Deploys destination chain components (Base Sepolia)
   - Sets up vault and transporter contracts

4. **HelperConfig.s.sol**
   - Deployment configuration helper
   - Network-specific settings
   - Test configurations

## Available Commands

| Command | Description |
|---------|------------|
| `make dev-setup` | Complete development setup (env, install, build) |
| `make dev-test` | Build and run all tests |
| `make test` | Run all tests |
| `make test-verbose` | Run tests with verbose output |
| `make test-coverage` | Run tests with coverage report |
| `make test-gas` | Run tests with gas reporting |
| `make test-match MATCH=<pattern>` | Run specific test(s) |
| `make format` | Format all Solidity files |
| `make lint` | Run solhint linter |
| `make deploy-local` | Deploy to local Anvil network |
| `make deploy-source RPC_URL=<url>` | Deploy source contracts |
| `make deploy-destination RPC_URL=<url>` | Deploy destination contracts |
| `make anvil` | Start local Anvil instance |
| `make anvil-fork-sepolia` | Start Anvil forked from Sepolia |
| `make size` | Show contract sizes |
| `make security` | Run Slither & Mythril analysis |
| `make verify-sepolia` | Verify contracts on Sepolia |
| `make verify-base-sepolia` | Verify contracts on Base Sepolia |


## Security Features

- **Access Control**: Only authorized transporters can call vault functions
- **Token Validation**: Proper token mapping between chains
- **Balance Checks**: Ensures sufficient balances before operations
- **Safe Token Transfers**: Uses OpenZeppelin's SafeERC20 for secure token operations
- **CCIP Security**: Leverages Chainlink's secure cross-chain infrastructure

## Dependencies

- **Chainlink CCIP**: Cross-chain interoperability protocol
- **OpenZeppelin Contracts**: Secure smart contract libraries
- **Foundry**: Development framework and testing suite

## Important Notes

1. **Token Mapping**: Always set up proper token mappings before cross-chain operations
2. **Gas Limits**: Ensure sufficient gas for cross-chain transactions
3. **Network Configuration**: Verify chain selectors and router addresses for each network
4. **Security**: Never share private keys or sensitive configuration data

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support:

- Open an issue on GitHub
- Check the [Chainlink CCIP documentation](https://docs.chain.link/ccip)
- Review the test files for usage examples

---

**Disclaimer**: This software is for educational and development purposes. Use at your own risk in production environments.
