// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    HelperConfig helperConfig;

    function setUp() public {
        helperConfig = new HelperConfig();
    }

    function testGetConfig() public {
        vm.chainId(11155111);
        HelperConfig.NetworkConfig memory networkConfig  = helperConfig.getConfig();
        (address router, address link) = (networkConfig.routerAddress, networkConfig.linkToken);

        assertEq(router, 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59);
        assertEq(link, 0x779877A7B0D9E8603169DdbD7836e478b4624789);

        vm.chainId(84532);
        networkConfig  = helperConfig.getConfig();
        (router, link) = (networkConfig.routerAddress, networkConfig.linkToken);

        assertEq(router, 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93);
        assertEq(link, 0xE4aB69C077896252FAFBD49EFD26B5D171A32410);
    }

    function testConfigReverts() public {
        vm.chainId(1);
        vm.expectRevert(abi.encodeWithSelector(HelperConfig.HelperConfig__InvalidChainId.selector, 1));
        helperConfig.getConfig();
    }
}