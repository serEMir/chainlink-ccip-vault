//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRouterClient} from
    "../lib/chainlink-local/lib/chainlink-ccip/chains/evm/contracts/interfaces/IRouterClient.sol";
import {Client} from "../lib/chainlink-local/lib/chainlink-ccip/chains/evm/contracts/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CCIPReceiver} from
    "../lib/chainlink-local/lib/chainlink-ccip/chains/evm/contracts/applications/CCIPReceiver.sol";
import {IReceiverVault} from "./interfaces/IReceiverVault.sol";

contract CCIPTransporter is CCIPReceiver, Ownable {
    error CCIPTransporter__NotAllowedForSourceChainOrSenderAddress(uint64 sourceChainSelector, address sender);
    error CCIPTransporter__FunctionCallFailed();
    error CCIPTransporter__SenderNotSet();

    uint64 private sourceChainSelector;
    address private s_sender;

    event MessageReceived(
        bytes32 indexed messageId,
        address indexed sender,
        uint64 indexed sourceChainSelector,
        bytes data,
        address token,
        uint256 amount
    );
    event SourceChainSelectorUpdated(uint64 indexed newSourceChainSelector);

    mapping(address => address) public sourceToDestToken;

    constructor(address _destinationRouter) CCIPReceiver(_destinationRouter) Ownable(msg.sender) {}

    modifier onlyAllowListed(uint64 _sourceChainSelector, address _sender) {
        if (s_sender == address(0)) {
            revert CCIPTransporter__SenderNotSet();
        }

        if (_sourceChainSelector != sourceChainSelector || _sender != s_sender) {
            revert CCIPTransporter__NotAllowedForSourceChainOrSenderAddress(_sourceChainSelector, _sender);
        }
        _;
    }

    function setTokenMapping(address sourceToken, address destToken) internal {
        sourceToDestToken[sourceToken] = destToken;
    }

    function setSender(address _sender) external onlyOwner {
        s_sender = _sender;
    }

    function setSourceChainSelector(uint64 _sourceChainSelector) external onlyOwner {
        sourceChainSelector = _sourceChainSelector;

        emit SourceChainSelectorUpdated(_sourceChainSelector);
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
        onlyAllowListed(any2EvmMessage.sourceChainSelector, abi.decode(any2EvmMessage.sender, (address)))
    {
        (address target, bytes memory functionCallData) = abi.decode(any2EvmMessage.data, (address, bytes));
        address receivedToken = address(0);
        uint256 receivedAmount = 0;
        if (any2EvmMessage.destTokenAmounts.length > 0) {
            receivedToken = any2EvmMessage.destTokenAmounts[0].token;
            receivedAmount = any2EvmMessage.destTokenAmounts[0].amount;

            IERC20(any2EvmMessage.destTokenAmounts[0].token).transfer(target, any2EvmMessage.destTokenAmounts[0].amount);
        }

        bytes memory rebuiltCalldata;

        if (functionCallData.length == 64) {
            // This is a depositToken call
            (address account, address srcToken) = abi.decode(functionCallData, (address, address));

            // implementation for making setting sourceToDestToken mapping automatic
            setTokenMapping(srcToken, receivedToken);
            rebuiltCalldata =
                abi.encodeWithSelector(IReceiverVault.depositToken.selector, account, receivedToken, receivedAmount);
        } else if (functionCallData.length == 128) {
            // This is a withdrawToken call
            (uint64 sourceChainSelector_, address account, address srcToken, uint256 amount) =
                abi.decode(functionCallData, (uint64, address, address, uint256));

            address destToken = sourceToDestToken[srcToken];
            require(destToken != address(0), "Token not mapped");

            rebuiltCalldata = abi.encodeWithSelector(
                IReceiverVault.withdrawToken.selector, sourceChainSelector_, account, destToken, amount
            );
        } else {
            revert CCIPTransporter__FunctionCallFailed();
        }

        (bool success,) = target.call(rebuiltCalldata);

        if (!success) {
            revert CCIPTransporter__FunctionCallFailed();
        }

        emit MessageReceived(
            any2EvmMessage.messageId,
            abi.decode(any2EvmMessage.sender, (address)),
            any2EvmMessage.sourceChainSelector,
            any2EvmMessage.data,
            receivedToken,
            receivedAmount
        );
    }
}
