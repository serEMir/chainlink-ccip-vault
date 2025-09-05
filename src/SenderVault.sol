// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRouterClient} from
    "../lib/chainlink-local/lib/chainlink-ccip/chains/evm/contracts/interfaces/IRouterClient.sol";
import {Client} from "../lib/chainlink-local/lib/chainlink-ccip/chains/evm/contracts/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IReceiverVault} from "../src/interfaces/IReceiverVault.sol";

/**
 * @title A cross-chain vault contract (SOURCE CHAIN).
 * @author SerEMir.
 * @notice A smart contract that allows users to make cross-chain vault deposit and withdrawal,
 * this contract was written to test what was possible with chainlink CCIP.
 * @dev Implements Chainlink CCIP.
 */
contract SenderVault is Ownable {
    using SafeERC20 for IERC20;

    error DepositVault__InsufficientBalance(address token, uint256 availableAmount, uint256 requiredAmount);

    /// @notice used to keep track of tokens, this contract doesn't store any tokens
    mapping(address => mapping(address => uint256)) userDeposit;

    IRouterClient private immutable iROUTER;
    IERC20 private immutable iLINK_TOKEN;

    event DepositSent(
        bytes32 messageId,
        address indexed receiver,
        uint64 indexed destinationChainSelector,
        uint256 amount,
        uint256 ccipFee
    );

    event WithdrawRequested(
        bytes32 messageId,
        address indexed receiver,
        uint64 indexed destinationChainSelector,
        uint256 amount,
        uint256 ccipFee
    );

    constructor(address _routerAddress, address _linkToken) Ownable(msg.sender) {
        iROUTER = IRouterClient(_routerAddress);
        iLINK_TOKEN = IERC20(_linkToken);
    }

    function depositToken(
        address _token,
        uint64 _destinationChainSelector,
        address _receiver,
        address _target,
        uint256 _amount
    ) external returns (bytes32 messageId) {
        if (_amount > IERC20(_token).balanceOf(msg.sender)) {
            revert DepositVault__InsufficientBalance(_token, IERC20(_token).balanceOf(msg.sender), _amount);
        }

        userDeposit[msg.sender][_token] += _amount;

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({token: _token, amount: _amount});
        tokenAmounts[0] = tokenAmount;

        bytes memory depositFunctionCalldata = abi.encode(msg.sender, _token);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode(_target, depositFunctionCalldata),
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 500000})),
            feeToken: address(iLINK_TOKEN)
        });

        uint256 ccipFee = iROUTER.getFee(_destinationChainSelector, message);

        if (ccipFee > iLINK_TOKEN.balanceOf(address(this))) {
            revert DepositVault__InsufficientBalance(
                address(iLINK_TOKEN), iLINK_TOKEN.balanceOf(address(this)), ccipFee
            );
        }
        iLINK_TOKEN.safeIncreaseAllowance(address(iROUTER), ccipFee);

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(address(iROUTER), _amount);

        messageId = iROUTER.ccipSend(_destinationChainSelector, message);

        emit DepositSent(messageId, _receiver, _destinationChainSelector, _amount, ccipFee);
    }

    function withdrawToken(
        address _token,
        uint64 _destinationChainSelector,
        uint64 _sourceChainSelector,
        address _receiver,
        address _target,
        uint256 _amount
    ) external returns (bytes32 messageId) {
        if (userDeposit[msg.sender][_token] < _amount) {
            revert DepositVault__InsufficientBalance(_token, userDeposit[msg.sender][_token], _amount);
        }

        userDeposit[msg.sender][_token] -= _amount;

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](0);

        bytes memory withdrawFunctionCalldata = abi.encode(_sourceChainSelector, msg.sender, _token, _amount);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver),
            data: abi.encode(_target, withdrawFunctionCalldata),
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 300000})),
            feeToken: address(iLINK_TOKEN)
        });

        uint256 ccipFee = iROUTER.getFee(_destinationChainSelector, message);

        if (ccipFee > iLINK_TOKEN.balanceOf(address(this))) {
            revert DepositVault__InsufficientBalance(
                address(iLINK_TOKEN), iLINK_TOKEN.balanceOf(address(this)), ccipFee
            );
        }
        iLINK_TOKEN.approve(address(iROUTER), ccipFee);

        messageId = iROUTER.ccipSend(_destinationChainSelector, message);

        emit WithdrawRequested(messageId, _receiver, _destinationChainSelector, _amount, ccipFee);
    }

    function getUserTokenBalance(address _user, address _token) external view returns (uint256) {
        return userDeposit[_user][_token];
    }
}
