// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {
    IRouterClient,
    LinkToken,
    BurnMintERC677Helper,
    CCIPLocalSimulator
} from "../lib/chainlink-local/src/ccip/CCIPLocalSimulator.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId(uint256 chainId);

    struct NetworkConfig {
        address routerAddress;
        address linkToken;
    }

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaConfig();
        networkConfigs[BASE_SEPOLIA_CHAIN_ID] = getBaseSepoliaConfig();
    }

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        NetworkConfig memory config = networkConfigs[chainId];

        if (chainId == ETH_SEPOLIA_CHAIN_ID || chainId == BASE_SEPOLIA_CHAIN_ID) {
            return config;
        } else {
            revert HelperConfig__InvalidChainId(chainId);
        }
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            routerAddress: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789
        });
    }

    function getBaseSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            routerAddress: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            linkToken: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410
        });
    }
}
