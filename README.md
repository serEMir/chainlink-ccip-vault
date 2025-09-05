# Cross-Chain Vault System

A decentralized cross-chain vault system that enables users to deposit and withdraw tokens across different blockchain networks using Chainlink's Cross-Chain Interoperability Protocol (CCIP).

## Quick Start

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone the repository
git clone https://github.com/serEMir/CCIPpoweredcrosschainvault.git
cd chainlink

# Install dependencies and build
make dev-setup

# Configure environment
make setup-env        # Creates .env template
```

## Components

- `SenderVault`: Source chain vault, initiates transfers
- `ReceiverVault`: Destination chain vault
- `CCIPTransporter`: CCIP message handler

## Commands

```bash
# Testing
make test                        # Run all tests
make test-match MATCH=<name>    # Run specific test

# Local Development
make anvil                      # Start local node
make deploy-local              # Deploy contracts

# Testnet Deployment
make deploy-source RPC_URL=$SEPOLIA_RPC_URL
make deploy-destination RPC_URL=$BASE_SEPOLIA_RPC_URL

# Other
make format                     # Format code
make security                   # Run security checks
make size                      # Show contract sizes
```

View all available commands with `make help`

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
