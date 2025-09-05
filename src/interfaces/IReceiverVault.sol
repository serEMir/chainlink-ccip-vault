// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IReceiverVault {
    function depositToken(address _account, address _token, uint256 _amount) external;
    function withdrawToken(uint64 _destinationChainSelector, address _account, address _token, uint256 _amount)
        external;
}
