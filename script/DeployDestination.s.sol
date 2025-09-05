// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {ReceiverVault} from "../src/ReceiverVault.sol";
import {CCIPTransporter} from "../src/CCIPTransporter.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/**
 * This script deploys the ReceiverVault and CCIPTransporter contracts.
 * It uses the configuration from HelperConfig to get the router address and LINK token address.
 */
contract DeployDestination is Script {
    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        ReceiverVault receiverVault = new ReceiverVault(config.linkToken, config.routerAddress);
        CCIPTransporter ccipTransporter = new CCIPTransporter(config.routerAddress);
        receiverVault.setTransporter(address(ccipTransporter));
        vm.stopBroadcast();

        console.log("ReceiverVault deployed to:", address(receiverVault));
        console.log("CCIPTransporter deployed to:", address(ccipTransporter));
    }
}
