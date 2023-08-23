pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

import "../../libraries/math/PayoutMath.sol";

contract SellerCollectPayout is BaseTest {
    using SilicaV2_1Storage for SilicaV2_1;

    address buyer1Address = address(12345);
    address buyer2Address = address(6789);

    SilicaV2_1 testSilicaV2_1;

    uint256 hashrate = 60000000000000; //60000 gh
    uint256 lastDueDay = 44;
    uint256 unitPrice = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT | reservedPrice = 14667422

    function setUp() public override {
        super.setUp();
        //SELLER CREATES SILICA
        uint256 sellerRewardBalance = 10000000000000000000000000;

        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate, lastDueDay, unitPrice)
        );
        cheats.stopPrank();
    }

    function testSellerCollectPayoutWithExcessWhenBuyerDepositIsVerySmallAndInitialCollateralCoversTheContractWithExcess() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = 424242;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);

        for (uint32 day = 42; day <= lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), uint32(lastDueDay + 1));
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Finished));

        uint256 contractBalanceBeforeCP = rewardToken.balanceOf(address(testSilicaV2_1));
        uint256 rewardDueWhenFinished = TestHelpers.getTotalRewardDueWhenFinished(address(testSilicaV2_1), address(rewardTokenOracle), 40);
        uint256 expectedExcess = contractBalanceBeforeCP - rewardDueWhenFinished;
        uint256 sellerRewardBalanceBeforeCP = rewardToken.balanceOf(sellerAddress);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();

        assertEq(testSilicaV2_1.rewardExcess(), expectedExcess);
        assertEq(rewardToken.balanceOf(sellerAddress), sellerRewardBalanceBeforeCP + expectedExcess);
        assertEq(paymentToken.balanceOf(sellerAddress), buyerDeposit);
    }

    function testSellerCollectPayout() public {
        uint256 totalUpfrontPayment = 424242424242;
        uint256 rewardExcess = 10000000;
        uint256 initialCollateral = testSilicaV2_1.initialCollateral();

        testSilicaV2_1.setFinishDay(1);
        testSilicaV2_1.setRewardExcess(rewardExcess);

        cheats.startPrank(address(testSilicaV2_1));
        rewardToken.getFaucet(rewardExcess);
        paymentToken.getFaucet(totalUpfrontPayment);
        cheats.stopPrank();

        uint256 sellerRewardBalanceBeforeCP = rewardToken.balanceOf(sellerAddress);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();

        assertEq(rewardToken.balanceOf(sellerAddress), sellerRewardBalanceBeforeCP + rewardExcess);
        assertEq(paymentToken.balanceOf(sellerAddress), totalUpfrontPayment);
        assertEq(rewardToken.balanceOf(address(testSilicaV2_1)), initialCollateral);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), 0);
        assertEq(testSilicaV2_1.didSellerCollectPayout(), true);
    }

    function testSellerCollectPayoutTwice() public {
        testSilicaV2_1.setFinishDay(1);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();

        cheats.prank(sellerAddress);
        cheats.expectRevert("Payout already collected");
        testSilicaV2_1.sellerCollectPayout();
    }

    function testNotASellerCallingSellerCollectPayout() public {
        testSilicaV2_1.setStatus(SilicaV2_1Types.Status.Finished);

        address fakeSeller = address(42);
        cheats.prank(fakeSeller);
        cheats.expectRevert("Not Owner");
        testSilicaV2_1.sellerCollectPayout();
    }

    function testSellerCollectPayoutWhenOpen() public {
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Open));

        cheats.prank(sellerAddress);
        cheats.expectRevert("Not Finished");
        testSilicaV2_1.sellerCollectPayout();
    }

    function testSellerCollectPayoutWhenExpired() public {
        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Expired));

        cheats.prank(sellerAddress);
        cheats.expectRevert("Not Finished");
        testSilicaV2_1.sellerCollectPayout();
    }

    function testSellerCollectPayoutWhenRunning() public {
        uint256 buyerDepositAmount = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        testSilicaV2_1.deposit(buyerDepositAmount);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);

        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        cheats.prank(sellerAddress);
        cheats.expectRevert("Not Finished");
        testSilicaV2_1.sellerCollectPayout();
    }

    function testSellerCollectPayoutWhenDefaulted() public {
        testSilicaV2_1.setDefaultDay(1);

        cheats.prank(sellerAddress);
        cheats.expectRevert("Not Finished");
        testSilicaV2_1.sellerCollectPayout();
    }
}
