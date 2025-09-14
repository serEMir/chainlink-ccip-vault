// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployLocal} from "../script/DeployLocal.s.sol";
import {DeploySenderVault} from "../script/DeploySenderVault.s.sol";
import {DeployDestination} from "../script/DeployDestination.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract DeploymentTest is Test {
    DeployLocal deployLocal;
    DeploySenderVault senderDeployer;
    DeployDestination receiverDeployer;
    HelperConfig config;

    uint64 constant LOCAL_CHAIN_ID = 31337;
    uint64 constant SEPOLIA_CHAIN_ID = 11155111;
    uint64 constant BASE_CHAIN_ID = 84532;


    function setUp() public {
        vm.setEnv("PRIVATE_KEY", "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
        deployLocal = new DeployLocal();
        senderDeployer = new DeploySenderVault();
        receiverDeployer = new DeployDestination();
        config = new HelperConfig();
    }

    function testCanDeployAll() public {
        deployLocal.run();

        vm.chainId(SEPOLIA_CHAIN_ID);
        senderDeployer.run();

        vm.chainId(BASE_CHAIN_ID);
        receiverDeployer.run();
    }

    function testLocalDeploy() public {
        vm.chainId(31337);
        vm.recordLogs();
        deployLocal.run();
        
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertTrue(entries.length > 0);
    }

    function testSepoliaDeploy() public {
        vm.chainId(11155111);
        vm.recordLogs();
        senderDeployer.run();
        
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertTrue(entries.length > 0);
    }
    function testBaseSepoliaDeploy() public {
        vm.chainId(84532);
        vm.recordLogs();
        receiverDeployer.run();
        
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertTrue(entries.length > 0);
    }
}