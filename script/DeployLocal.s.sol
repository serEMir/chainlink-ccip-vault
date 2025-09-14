// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SenderVault} from "../src/SenderVault.sol";
import {ReceiverVault} from "../src/ReceiverVault.sol";
import {CCIPTransporter} from "../src/CCIPTransporter.sol";

/**
 * This script deploys all contracts for local development.
 * It uses hardcoded addresses for local Anvil network.
 */
contract DeployLocal is Script {
    address constant ROUTER_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant LINK_TOKEN = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;


    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SenderVault senderVault = new SenderVault(ROUTER_ADDRESS, LINK_TOKEN);
        console.log("SenderVault deployed to:", address(senderVault));

        CCIPTransporter ccipTransporter = new CCIPTransporter(ROUTER_ADDRESS);
        console.log("CCIPTransporter deployed to:", address(ccipTransporter));

        ReceiverVault receiverVault = new ReceiverVault(LINK_TOKEN, ROUTER_ADDRESS);
        console.log("ReceiverVault deployed to:", address(receiverVault));

        receiverVault.setTransporter(address(ccipTransporter));
        console.log("ReceiverVault configured with CCIPTransporter");

        vm.stopBroadcast();

        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("SenderVault:", address(senderVault));
        console.log("ReceiverVault:", address(receiverVault));
        console.log("CCIPTransporter:", address(ccipTransporter));
        console.log("Router Address:", ROUTER_ADDRESS);
        console.log("LINK Token:", LINK_TOKEN);
    }
}
