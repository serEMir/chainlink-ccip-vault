// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {SenderVault} from "../src/SenderVault.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeploySenderVault is Script {
    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        SenderVault senderVault = new SenderVault(config.routerAddress, config.linkToken);
        vm.stopBroadcast();

        console.log("SenderVault deployed to:", address(senderVault));
    }
}
