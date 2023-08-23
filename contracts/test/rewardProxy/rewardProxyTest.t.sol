pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import "../../libraries/math/PayoutMath.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";
import {ISilicaV2_1} from "../../interfaces/silica/ISilicaV2_1.sol";
import {RewardsProxy} from "../../RewardsProxy.sol";
import {IRewardsProxy} from "../../interfaces/rewardsProxy/IRewardsProxy.sol";
import "@std/console.sol";

contract RewardsProxyTest is BaseTest {
    ISilicaV2_1 testSilicaV2_1_0;
    ISilicaV2_1 testSilicaV2_1_1;
    ISilicaV2_1 testSilicaV2_1_2;

    IRewardsProxy testRewardsProxy;

    function setUp() public override {
        super.setUp();

        //DEPLOY REWARDSPROXY
        testRewardsProxy = new RewardsProxy(address(oracleRegistry));

        //SELLER CREATES SILICAS
        uint256 sellerRewardBalance = 10000000000000000000000000;

        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);

        //SILCA 0
        uint256 hashrate0 = 60000000000000; // 0.06 PH
        uint256 lastDueDay0 = 44;
        uint256 unitPrice0 = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT
        testSilicaV2_1_0 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate0, lastDueDay0, unitPrice0)
        );

        //SILICA 1
        uint256 hashrate1 = 80000000000000; // 0.08 PH
        uint256 lastDueDay1 = 55;
        uint256 unitPrice1 = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT
        testSilicaV2_1_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate1, lastDueDay1, unitPrice1)
        );

        //SILICA 2
        uint256 hashrate2 = 400000000000000; // 0.4 PH
        uint256 lastDueDay2 = 90;
        uint256 unitPrice2 = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT
        testSilicaV2_1_2 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate2, lastDueDay2, unitPrice2)
        );
        cheats.stopPrank();

        //BUYER BUYS INTO THE SILICAS
        uint256 buyerDepositAmount0 = 4242424; // max = 0.06 * 3 * 81485680 = 14667422
        uint256 buyerDepositAmount1 = 42424242; // max = 0.08 * 14 * 81485680 = 91263961
        uint256 buyerDepositAmount2 = 42424242; // max = 0.4 * 49 * 81485680 = 1597119328

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount0 + buyerDepositAmount1 + buyerDepositAmount2);

        //SILICA 0 DEPOSIT
        paymentToken.approve(address(testSilicaV2_1_0), buyerDepositAmount0);
        testSilicaV2_1_0.deposit(buyerDepositAmount0);

        //SILICA 1 DEPOSIT
        paymentToken.approve(address(testSilicaV2_1_1), buyerDepositAmount1);
        testSilicaV2_1_1.deposit(buyerDepositAmount1);

        //SILICA 2 DEPOSIT
        paymentToken.approve(address(testSilicaV2_1_2), buyerDepositAmount2);
        testSilicaV2_1_2.deposit(buyerDepositAmount2);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 42);
    }

    function testStreamRewards() public {
        IRewardsProxy.StreamRequest[] memory streamRequests = new IRewardsProxy.StreamRequest[](3);

        streamRequests[0].silicaAddress = address(testSilicaV2_1_0);
        streamRequests[0].rToken = address(rewardToken);
        streamRequests[0].amount = testSilicaV2_1_0.getRewardDueNextOracleUpdate();

        streamRequests[1].silicaAddress = address(testSilicaV2_1_1);
        streamRequests[1].rToken = address(rewardToken);
        streamRequests[1].amount = testSilicaV2_1_1.getRewardDueNextOracleUpdate();

        streamRequests[2].silicaAddress = address(testSilicaV2_1_2);
        streamRequests[2].rToken = address(rewardToken);
        streamRequests[2].amount = testSilicaV2_1_2.getRewardDueNextOracleUpdate();

        uint256[] memory silicaRewardBalanceBeforeStream = new uint256[](3);

        silicaRewardBalanceBeforeStream[0] = rewardToken.balanceOf(address(testSilicaV2_1_0));
        silicaRewardBalanceBeforeStream[1] = rewardToken.balanceOf(address(testSilicaV2_1_1));
        silicaRewardBalanceBeforeStream[2] = rewardToken.balanceOf(address(testSilicaV2_1_2));

        uint256 totalRewardDue = streamRequests[0].amount + streamRequests[1].amount + streamRequests[2].amount;
        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(totalRewardDue);
        rewardToken.approve(address(testRewardsProxy), totalRewardDue);
        testRewardsProxy.streamRewards(streamRequests);
        cheats.stopPrank();

        assertEq(rewardToken.balanceOf(address(testSilicaV2_1_0)), silicaRewardBalanceBeforeStream[0] + streamRequests[0].amount);
        assertEq(rewardToken.balanceOf(address(testSilicaV2_1_1)), silicaRewardBalanceBeforeStream[1] + streamRequests[1].amount);
        assertEq(rewardToken.balanceOf(address(testSilicaV2_1_2)), silicaRewardBalanceBeforeStream[2] + streamRequests[2].amount);

        //BONUS CHECK
        assertEq(testSilicaV2_1_0.getRewardDueNextOracleUpdate(), 0);
        assertEq(testSilicaV2_1_0.getRewardDueNextOracleUpdate(), 0);
        assertEq(testSilicaV2_1_0.getRewardDueNextOracleUpdate(), 0);
    }

    function testFuzzStreamRewards(address _testSilicaV2_1_0, uint256 _amount) public {
        vm.assume(_testSilicaV2_1_0 != address(0));
        vm.assume(_amount < 1e76);
        IRewardsProxy.StreamRequest[] memory streamRequests = new IRewardsProxy.StreamRequest[](3);

        streamRequests[0].silicaAddress = _testSilicaV2_1_0;
        streamRequests[0].rToken = address(rewardToken);
        streamRequests[0].amount = _amount;

        streamRequests[1].silicaAddress = _testSilicaV2_1_0;
        streamRequests[1].rToken = address(rewardToken);
        streamRequests[1].amount = _amount;

        streamRequests[2].silicaAddress = _testSilicaV2_1_0;
        streamRequests[2].rToken = address(rewardToken);
        streamRequests[2].amount = _amount;

        uint256[] memory silicaRewardBalanceBeforeStream = new uint256[](3);

        silicaRewardBalanceBeforeStream[0] = rewardToken.balanceOf(_testSilicaV2_1_0);
        silicaRewardBalanceBeforeStream[1] = rewardToken.balanceOf(_testSilicaV2_1_0);
        silicaRewardBalanceBeforeStream[2] = rewardToken.balanceOf(_testSilicaV2_1_0);

        uint256 totalRewardDue = streamRequests[0].amount + streamRequests[1].amount + streamRequests[2].amount;
        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(totalRewardDue);
        rewardToken.approve(address(testRewardsProxy), totalRewardDue);
        uint256 balanceBefore = rewardToken.balanceOf(_testSilicaV2_1_0);
        testRewardsProxy.streamRewards(streamRequests);
        cheats.stopPrank();

        assertEq(rewardToken.balanceOf(_testSilicaV2_1_0), balanceBefore + totalRewardDue);
    }
}
