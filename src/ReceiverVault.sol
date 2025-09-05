//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRouterClient} from
    "../lib/chainlink-local/lib/chainlink-ccip/chains/evm/contracts/interfaces/IRouterClient.sol";
import {Client} from "../lib/chainlink-local/lib/chainlink-ccip/chains/evm/contracts/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title A cross-chain vault contract (DESTINSTION CHAIN).
 * @author SerEMir.
 * @notice A smart contract that allows users to make cross-chain vault deposit and withdrawal,
 * this contract serves as the destination side of the cross-chain vault,
 * it's where tokens are actually being stored.
 * @dev Implements Chainlink CCIP.
 */
contract ReceiverVault is Ownable {
    using SafeERC20 for IERC20;

    error ReceiverVault__InvalidAmount();
    error ReceiverVault__InsufficientTokenBalance(address token, uint256 currentBalance, uint256 requiredAmount);
    error ReceiverVault__OnlyTransporter();

    mapping(address => mapping(address => uint256)) userDepositAmount;

    IERC20 private immutable iLINK_TOKEN;
    IRouterClient private immutable iROUTER;
    address private s_ccipTransporter;

    event TokenDeposited(address indexed account, address indexed token, uint256 amount);
    event TokenWithdrawn(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address indexed account,
        address token,
        uint256 amount,
        uint256 ccipFee
    );

    constructor(address _linkToken, address _routerAddress) Ownable(msg.sender) {
        iLINK_TOKEN = IERC20(_linkToken);
        iROUTER = IRouterClient(_routerAddress);
    }

    modifier onlyTransporter() {
        if (msg.sender != s_ccipTransporter) {
            revert ReceiverVault__OnlyTransporter();
        }
        _;
    }

    function setTransporter(address _transporter) external onlyOwner {
        s_ccipTransporter = _transporter;
    }

    function depositToken(address _account, address _token, uint256 _amount) external onlyTransporter {
        if (_amount <= 0) {
            revert ReceiverVault__InvalidAmount();
        }

        userDepositAmount[_account][_token] += _amount;

        emit TokenDeposited(_account, _token, _amount);
    }

    function withdrawToken(uint64 _destinationChainSelector, address _account, address _token, uint256 _amount)
        external
        returns (bytes32 messageId)
    {
        if (_amount <= 0) {
            revert ReceiverVault__InvalidAmount();
        }

        if (userDepositAmount[_account][_token] < _amount) {
            revert ReceiverVault__InsufficientTokenBalance(_token, userDepositAmount[_account][_token], _amount);
        }

        userDepositAmount[_account][_token] -= _amount;

        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({token: _token, amount: _amount});
        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_account),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 0})),
            feeToken: address(iLINK_TOKEN)
        });

        uint256 ccipFee = iROUTER.getFee(_destinationChainSelector, message);

        if (ccipFee > iLINK_TOKEN.balanceOf(address(this))) {
            revert ReceiverVault__InsufficientTokenBalance(
                address(iLINK_TOKEN), iLINK_TOKEN.balanceOf(address(this)), ccipFee
            );
        }
        iLINK_TOKEN.approve(address(iROUTER), ccipFee);

        IERC20(_token).approve(address(iROUTER), _amount);

        messageId = iROUTER.ccipSend(_destinationChainSelector, message);

        emit TokenWithdrawn(messageId, _destinationChainSelector, _account, _token, _amount, ccipFee);
    }

    function getUserTokenBalance(address _user, address _token) external view returns (uint256) {
        return userDepositAmount[_user][_token];
    }
}
