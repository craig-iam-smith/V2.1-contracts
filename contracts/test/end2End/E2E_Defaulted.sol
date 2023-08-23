pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import "../../libraries/math/PayoutMath.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

contract E2E_Defaulted is BaseTest {
    uint256 hashrate = 60000000000;
    uint32 lastDueDay = 43;
    uint256 unitPrice = 10000000;

    function setUp() public override {
        super.setUp();
    }

    function testE2E2DayToDefault() public {
        //SELLER CREATES SILICA
        cheats.startPrank(sellerAddress);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        SilicaV2_1 testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate, lastDueDay, unitPrice)
        );
        cheats.stopPrank();

        uint32 firstDueDay = testSilicaV2_1.firstDueDay();

        //BUYER DEPOSITS
        assertEq(0, testSilicaV2_1.balanceOf(buyerAddress));

        uint256 buyerDeposit = testSilicaV2_1.reservedPrice();

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        assertEq(hashrate, testSilicaV2_1.balanceOf(buyerAddress));
        assertEq(testSilicaV2_1.totalSupply(), testSilicaV2_1.balanceOf(buyerAddress));

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), firstDueDay - 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), firstDueDay);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        //SELLER DEPOSITS REWARD DUE NEXT UPDATE
        uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
        cheats.prank(sellerAddress);
        rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), firstDueDay + 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), firstDueDay + 2);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));

        //BUYER CLAIM REWARDS
        assertEq(rewardToken.balanceOf(buyerAddress), 0);
        uint256 buyerPaymentBalanceBeforeClaim = paymentToken.balanceOf(buyerAddress);
        uint256 numOfDepositsRequired = testSilicaV2_1.lastDueDay() + 1 - testSilicaV2_1.firstDueDay();
        uint256 buyerExpectedPaymentPayout = PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
            testSilicaV2_1.balanceOf(buyerAddress),
            buyerDeposit,
            hashrate,
            PayoutMath._getHaircut(testSilicaV2_1.getDayOfDefault() - testSilicaV2_1.firstDueDay(), numOfDepositsRequired)
        );

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayoutOnDefault();

        uint256 rewardDelivered = testSilicaV2_1.rewardDelivered();
        assertEq(rewardToken.balanceOf(buyerAddress), rewardDelivered);
        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalanceBeforeClaim + buyerExpectedPaymentPayout);

        //SELLER COLLECT PAYOUT
        rewardToken.balanceOf(sellerAddress);
        assertEq(paymentToken.balanceOf(sellerAddress), 0);

        uint256 sellerRewardBalanceBeforeCP = rewardToken.balanceOf(sellerAddress);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayoutDefault();

        assertEq(paymentToken.balanceOf(sellerAddress), buyerDeposit - buyerExpectedPaymentPayout);
        assertEq(rewardToken.balanceOf(sellerAddress), sellerRewardBalanceBeforeCP + testSilicaV2_1.rewardExcess()); //collateral unlock = excess

        //CHECKING FOR DUST OR ERROR IN CALCS
        assertEq(testSilicaV2_1.totalSupply(), 0);
        assertEq(rewardToken.balanceOf(address(testSilicaV2_1)), 0);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), 0);
    }
}
