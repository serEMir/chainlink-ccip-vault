// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {IReceiverVault} from "../src/interfaces/IReceiverVault.sol";
import {Client} from "../lib/chainlink-local/lib/chainlink-ccip/chains/evm/contracts/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    IRouterClient,
    LinkToken,
    BurnMintERC677Helper,
    CCIPLocalSimulator
} from "../lib/chainlink-local/src/ccip/CCIPLocalSimulator.sol";
import {Vm} from "forge-std/Vm.sol";
import {SenderVault} from "../src/SenderVault.sol";
import {ReceiverVault} from "../src/ReceiverVault.sol";
import {CCIPTransporter} from "../src/CCIPTransporter.sol";
import {IReceiverVault} from "../src/interfaces/IReceiverVault.sol";
import {TestableCCIPTransporter} from "../src/mocks/TestableCCIPTransporter.sol";

contract VaultTestV2 is Test {
    CCIPLocalSimulator private ccipLocalSimulator;
    SenderVault public senderVault;
    ReceiverVault public receiverVault;
    CCIPTransporter public ccipTransporter;
    TestableCCIPTransporter public testableCCIPTransporter;
    uint64 public destinationChainSelector;
    BurnMintERC677Helper public ccipBnMToken;
    BurnMintERC677Helper public ccipLnMToken;
    LinkToken public ilinkToken;
    IRouterClient public iRouter;
    Client.Any2EVMMessage public any2EvmMessage;

    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");
    uint256 linkForFees = 5 ether;
    uint256 amountToDeposit1 = 1 ether;
    uint256 amountToDeposit2 = 0.5 ether;

    function setUp() public {
        ccipLocalSimulator = new CCIPLocalSimulator();

        (
            uint64 chainSelector,
            IRouterClient sourceRouter,
            IRouterClient destinationRouter,
            ,
            LinkToken linkToken,
            BurnMintERC677Helper ccipBnM,
            BurnMintERC677Helper ccipLnM
        ) = ccipLocalSimulator.configuration();

        senderVault = new SenderVault(address(sourceRouter), address(linkToken));
        receiverVault = new ReceiverVault(address(linkToken), address(destinationRouter));

        ccipTransporter = new CCIPTransporter(address(destinationRouter));

        receiverVault.setTransporter(address(ccipTransporter));

        testableCCIPTransporter = new TestableCCIPTransporter(address(destinationRouter));

        iRouter = sourceRouter;

        testableCCIPTransporter.setSender(address(senderVault));
        testableCCIPTransporter.setSourceChainSelector(chainSelector);

        ccipTransporter.setSender(address(senderVault));
        ccipTransporter.setSourceChainSelector(chainSelector);

        ccipLocalSimulator.requestLinkFromFaucet(address(USER1), linkForFees);
        ccipLocalSimulator.requestLinkFromFaucet(address(USER2), linkForFees);
        ccipBnM.drip(USER1);
        ccipBnM.drip(USER2);
        ccipLnM.drip(USER1);
        destinationChainSelector = chainSelector;
        ccipBnMToken = ccipBnM;
        ccipLnMToken = ccipLnM;
        ilinkToken = linkToken;

        /*//////////////////////////////////////////////////////////////
                     TESTABLE_CCIPTRANSPORTER PREP
        //////////////////////////////////////////////////////////////*/

        any2EvmMessage.messageId = keccak256(
            abi.encodePacked(address(receiverVault), destinationChainSelector, address(ccipBnMToken), amountToDeposit1)
        );
        any2EvmMessage.sourceChainSelector = destinationChainSelector;
        any2EvmMessage.sender = abi.encode(address(senderVault));
        any2EvmMessage.data = abi.encode(address(receiverVault), abi.encode(address(USER1), address(ccipBnMToken)));
        any2EvmMessage.destTokenAmounts.push(
            Client.EVMTokenAmount({token: address(ccipBnMToken), amount: amountToDeposit1})
        );
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier prepDepositVault() {
        vm.startPrank(USER1);
        IERC20(address(ilinkToken)).transfer(address(senderVault), linkForFees);

        IERC20(address(ccipBnMToken)).approve(address(senderVault), amountToDeposit1);
        vm.stopPrank();
        _;
    }

    modifier prepTestCCIPTransporter() {
        deal(address(ccipBnMToken), address(testableCCIPTransporter), amountToDeposit1);
        _;
    }

    modifier prepWithdraw() {
        vm.startPrank(USER1);
        senderVault.depositToken(
            address(ccipBnMToken),
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit1
        );
        vm.stopPrank();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                DEPOSIT_TESTS 
    //////////////////////////////////////////////////////////////*/

    function testDepositSendsAndEmits() external prepDepositVault {
        vm.startPrank(USER1);

        vm.expectEmit(true, true, true, true);

        emit SenderVault.DepositSent(
            0x2274293f9a18b2ba7464d225c4bb4e0ae0a5659e1f722522b6630e0171d64ab0,
            address(ccipTransporter),
            destinationChainSelector,
            amountToDeposit1,
            0
        );
        senderVault.depositToken(
            address(ccipBnMToken),
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit1
        );
        vm.stopPrank();

        assertEq(senderVault.getUserTokenBalance(USER1, address(ccipBnMToken)), amountToDeposit1);
        assertEq(receiverVault.getUserTokenBalance(USER1, address(ccipBnMToken)), amountToDeposit1);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(receiverVault)), amountToDeposit1);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(senderVault)), 0);
    }

    function testSenderVaultRevertsTokenDepositIfInsufficientTokenBalance() external prepDepositVault {
        vm.startPrank(USER1);
        senderVault.depositToken(
            address(ccipBnMToken),
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit1
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SenderVault.DepositVault__InsufficientBalance.selector, address(ccipBnMToken), 0, amountToDeposit1
            )
        );

        senderVault.depositToken(
            address(ccipBnMToken),
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit1
        );
        vm.stopPrank();
    }

    function testMultipleDeposits() external prepDepositVault {
        vm.startPrank(USER1);
        senderVault.depositToken(
            address(ccipBnMToken),
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit2
        );
        senderVault.depositToken(
            address(ccipBnMToken),
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit2
        );
        vm.stopPrank();

        assertEq(senderVault.getUserTokenBalance(USER1, address(ccipBnMToken)), amountToDeposit2 + amountToDeposit2);
        assertEq(receiverVault.getUserTokenBalance(USER1, address(ccipBnMToken)), amountToDeposit2 + amountToDeposit2);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(receiverVault)), amountToDeposit2 + amountToDeposit2);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(senderVault)), 0);
    }

    function testDifferentTokenDeposits() external prepDepositVault {
        vm.startPrank(USER1);
        IERC20(address(ccipLnMToken)).approve(address(senderVault), amountToDeposit2);
        senderVault.depositToken(
            address(ccipBnMToken),
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit1
        );
        senderVault.depositToken(
            address(ccipLnMToken),
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit2
        );
        vm.stopPrank();

        assertEq(senderVault.getUserTokenBalance(USER1, address(ccipBnMToken)), amountToDeposit1);
        assertEq(receiverVault.getUserTokenBalance(USER1, address(ccipBnMToken)), amountToDeposit1);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(receiverVault)), amountToDeposit1);

        assertEq(senderVault.getUserTokenBalance(USER1, address(ccipLnMToken)), amountToDeposit2);
        assertEq(receiverVault.getUserTokenBalance(USER1, address(ccipLnMToken)), amountToDeposit2);
        assertEq(IERC20(address(ccipLnMToken)).balanceOf(address(receiverVault)), amountToDeposit2);
    }

    function testMultipleUserDeposit() external prepDepositVault {
        vm.startPrank(USER2);
        IERC20(address(ccipBnMToken)).approve(address(senderVault), amountToDeposit2);
        IERC20(address(ilinkToken)).transfer(address(senderVault), linkForFees);
        senderVault.depositToken(
            address(ccipBnMToken),
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit2
        );
        vm.stopPrank();

        vm.startPrank(USER1);
        senderVault.depositToken(
            address(ccipBnMToken),
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit1
        );
        vm.stopPrank();

        assertEq(senderVault.getUserTokenBalance(USER1, address(ccipBnMToken)), amountToDeposit1);
        assertEq(receiverVault.getUserTokenBalance(USER1, address(ccipBnMToken)), amountToDeposit1);
        assertEq(senderVault.getUserTokenBalance(USER2, address(ccipBnMToken)), amountToDeposit2);
        assertEq(receiverVault.getUserTokenBalance(USER2, address(ccipBnMToken)), amountToDeposit2);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(receiverVault)), amountToDeposit1 + amountToDeposit2);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(senderVault)), 0);
    }

    function testReceiverVaultRevertsTokenDepositIfInvalidAmount() external {
        vm.prank(address(ccipTransporter));
        vm.expectRevert(ReceiverVault.ReceiverVault__InvalidAmount.selector);
        receiverVault.depositToken(USER1, address(ccipBnMToken), 0);
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW_TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdrawTokenSucceedsAndEmits() external prepDepositVault prepWithdraw {
        vm.startPrank(USER1);
        vm.expectEmit(true, true, true, true);
        emit SenderVault.WithdrawRequested(
            0xe3b167c6ae99151ee84d65d3d48cd9925e71b2dbb0aa78f000c9b074aadc39c3,
            address(ccipTransporter),
            destinationChainSelector,
            amountToDeposit1,
            0
        );
        senderVault.withdrawToken(
            address(ccipBnMToken),
            destinationChainSelector,
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit1
        );
        vm.stopPrank();

        assertEq(senderVault.getUserTokenBalance(USER1, address(ccipBnMToken)), 0);
        assertEq(receiverVault.getUserTokenBalance(USER1, address(ccipBnMToken)), 0);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(receiverVault)), 0);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(USER1)), amountToDeposit1);
    }

    function testSenderVaultRevertsTokenWithdrawalIfInsufficientBalance() external {
        vm.startPrank(USER2);
        vm.expectRevert(
            abi.encodeWithSelector(
                SenderVault.DepositVault__InsufficientBalance.selector, address(ccipBnMToken), 0, amountToDeposit1
            )
        );
        senderVault.withdrawToken(
            address(ccipBnMToken),
            destinationChainSelector,
            destinationChainSelector,
            address(ccipTransporter),
            address(receiverVault),
            amountToDeposit1
        );
        vm.stopPrank();
    }

    function testReceiverVaultRevertsTokenWithdrawalIfInsufficientBalance() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                ReceiverVault.ReceiverVault__InsufficientTokenBalance.selector,
                address(ccipBnMToken),
                0,
                amountToDeposit1
            )
        );
        vm.prank(address(ccipTransporter));
        receiverVault.withdrawToken(destinationChainSelector, USER1, address(ccipBnMToken), amountToDeposit1);
    }

    function testReceiverVaultRevertsTokenWithdrawalIfInvalidAmount() external {
        vm.expectRevert(ReceiverVault.ReceiverVault__InvalidAmount.selector);
        vm.prank(address(ccipTransporter));
        receiverVault.withdrawToken(destinationChainSelector, USER1, address(ccipBnMToken), 0);
    }

    /*//////////////////////////////////////////////////////////////
                             CCIP_RECEIVER_TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ccipReceiveSucceedsAndEmits() external prepTestCCIPTransporter {
        receiverVault.setTransporter(address(testableCCIPTransporter));
        vm.prank(address(iRouter));
        vm.expectEmit(true, true, true, true);
        emit CCIPTransporter.MessageReceived(
            any2EvmMessage.messageId,
            address(senderVault),
            destinationChainSelector,
            any2EvmMessage.data,
            address(ccipBnMToken),
            amountToDeposit1
        );
        testableCCIPTransporter.test_ccipRecieve(any2EvmMessage);

        assertEq(receiverVault.getUserTokenBalance(USER1, address(ccipBnMToken)), amountToDeposit1);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(receiverVault)), amountToDeposit1);
        assertEq(IERC20(address(ccipBnMToken)).balanceOf(address(testableCCIPTransporter)), 0);
    }

    function test_ccipRecieveRevertsIfSenderNotAllowed() external prepTestCCIPTransporter {
        any2EvmMessage.sender = abi.encode(address(receiverVault));
        vm.prank(address(iRouter));
        vm.expectRevert(
            abi.encodeWithSelector(
                CCIPTransporter.CCIPTransporter__NotAllowedForSourceChainOrSenderAddress.selector,
                destinationChainSelector,
                address(receiverVault)
            )
        );
        testableCCIPTransporter.test_ccipRecieve(any2EvmMessage);
    }

    function test_ccipReceiveRevertsIfSenderNotSet() external prepTestCCIPTransporter {
        testableCCIPTransporter.setSender(address(0));
        vm.prank(address(iRouter));
        vm.expectRevert(abi.encodeWithSelector(CCIPTransporter.CCIPTransporter__SenderNotSet.selector));
        testableCCIPTransporter.test_ccipRecieve(any2EvmMessage);
    }

    function test_ccipReceiverRevertsIfFunctionCallFailed() external prepTestCCIPTransporter {
        any2EvmMessage.data = abi.encode(
            address(receiverVault),
            abi.encodeWithSelector(IReceiverVault.depositToken.selector, address(USER1), address(ccipBnMToken), 0)
        );
        any2EvmMessage.destTokenAmounts.push(Client.EVMTokenAmount({token: address(ccipBnMToken), amount: 0}));

        vm.prank(address(iRouter));
        vm.expectRevert(abi.encodeWithSelector(CCIPTransporter.CCIPTransporter__FunctionCallFailed.selector));

        testableCCIPTransporter.test_ccipRecieve(any2EvmMessage);
    }

    /*//////////////////////////////////////////////////////////////
                             RECEIVER_VAULT
    //////////////////////////////////////////////////////////////*/
    function testReceiverVaultRevertsIfNotTransporter() external {
        vm.expectRevert(abi.encodeWithSelector(ReceiverVault.ReceiverVault__OnlyTransporter.selector));
        receiverVault.depositToken(USER1, address(ccipBnMToken), amountToDeposit1);
    }

    function testReceiverVaultReturnsUserTokenBalance() external {
        vm.startPrank(address(ccipTransporter));
        receiverVault.depositToken(USER1, address(ccipBnMToken), amountToDeposit1);
        vm.stopPrank();
        uint256 balance = receiverVault.getUserTokenBalance(USER1, address(ccipBnMToken));
        assertEq(balance, amountToDeposit1);
    }
}