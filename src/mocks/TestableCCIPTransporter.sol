// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {CCIPTransporter} from "../CCIPTransporter.sol";
import {Client} from "../../lib/chainlink-local/lib/chainlink-ccip/chains/evm/contracts/libraries/Client.sol";

contract TestableCCIPTransporter is CCIPTransporter {
    address private s_sender;
    uint64 private sourceChainSelector;

    constructor(address _destinationRouter) CCIPTransporter(_destinationRouter) {}

    function test_ccipRecieve(Client.Any2EVMMessage memory any2EvmMessage)
        external
        onlyAllowListed(any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)))
    {
        _ccipReceive(any2EvmMessage);
    }
}
