pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

contract E2E_Finish is BaseTest {
    uint256 hashrate = 1000000000000000; //1 PH/s
    uint32 lastDueDay = 44;
    uint256 unitPrice = 81; //81 USDT / PH ==> 0.000081 USDT / GH

    function setUp() public override {
        super.setUp();
    }

    function testE2E3DayToFinish() public {
        //SELLER CREATES SILICA
        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        SilicaV2_1 testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate, lastDueDay, unitPrice)
        );
        cheats.stopPrank();

        uint32 firstDueDay = testSilicaV2_1.firstDueDay();

        //InitialMath check
        uint256 expectedReservedPrice = TestHelpers.getReservedPrice(address(testSilicaV2_1), unitPrice);
        uint256 expectedInitialCollateral = TestHelpers.getInitialCollateral(address(testSilicaV2_1), address(rewardTokenOracle));

        assertEq(testSilicaV2_1.reservedPrice(), expectedReservedPrice);
        assertEq(testSilicaV2_1.initialCollateral(), expectedInitialCollateral);

        //BUYER DEPOSITS
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Open));
        assertEq(testSilicaV2_1.balanceOf(buyerAddress), 0);

        uint256 buyerDeposit = testSilicaV2_1.reservedPrice() / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        assertEq(testSilicaV2_1.balanceOf(buyerAddress), (hashrate * buyerDeposit) / testSilicaV2_1.reservedPrice());
        assertEq(testSilicaV2_1.totalSupply(), testSilicaV2_1.balanceOf(buyerAddress));

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), firstDueDay - 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        for (uint32 day = firstDueDay; day <= lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay + 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Finished));
        assertEq(
            rewardToken.balanceOf(address(testSilicaV2_1)),
            TestHelpers.getContractBalanceOnDay(address(testSilicaV2_1), address(rewardTokenOracle))
        );

        //BUYER CLAIM REWARDS
        assertEq(rewardToken.balanceOf(buyerAddress), 0);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();

        assertEq(rewardToken.balanceOf(buyerAddress), testSilicaV2_1.rewardDelivered());

        //SELLER COLLECT PAYOUT
        assertEq(paymentToken.balanceOf(sellerAddress), 0);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();

        assertEq(paymentToken.balanceOf(sellerAddress), buyerDeposit);

        //CHECKING FOR DUST OR ERROR IN CALCS
        assertEq(testSilicaV2_1.totalSupply(), 0);
        assertEq(rewardToken.balanceOf(address(testSilicaV2_1)), 0);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), 0);
    }

    function testE2E60DaysToFinish() public {
        //SELLER CREATES SILICA
        lastDueDay = 101; //60 days

        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
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

        for (uint32 day = firstDueDay; day <= lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay + 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Finished));

        //BUYER CLAIM REWARDS
        assertEq(rewardToken.balanceOf(buyerAddress), 0);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();

        assertEq(rewardToken.balanceOf(buyerAddress), testSilicaV2_1.rewardDelivered());

        //SELLER COLLECT PAYOUT
        assertEq(paymentToken.balanceOf(sellerAddress), 0);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();

        assertEq(paymentToken.balanceOf(sellerAddress), buyerDeposit);
    }

    function testE2E120DaysToFinish() public {
        //SELLER CREATES SILICA
        lastDueDay = 161; //120 days

        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
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

        for (uint32 day = firstDueDay; day <= lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay + 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Finished));

        //BUYER CLAIM REWARDS
        assertEq(rewardToken.balanceOf(buyerAddress), 0);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();

        assertEq(rewardToken.balanceOf(buyerAddress), testSilicaV2_1.rewardDelivered());

        //SELLER COLLECT PAYOUT
        assertEq(paymentToken.balanceOf(sellerAddress), 0);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();

        assertEq(paymentToken.balanceOf(sellerAddress), buyerDeposit);
    }
}
