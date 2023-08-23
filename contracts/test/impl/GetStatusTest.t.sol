pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

contract GetStatus is BaseTest {
    using SilicaV2_1Storage for SilicaV2_1;

    SilicaV2_1 testSilicaV2_1;

    uint256 hashrate = 60000000000000; //60000 gh
    uint32 lastDueDay = 44;
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

    function testGetStatusOpen() public {
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Open));
    }

    function testGetStatusExpired() public {
        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), testSilicaV2_1.firstDueDay() - 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Expired));
    }

    function testGetStatusRunning() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), testSilicaV2_1.firstDueDay() - 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        for (uint32 day = testSilicaV2_1.firstDueDay(); day <= lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);
        }
    }

    function testGetStatusDefaultedFirstDueDay() public {
        //BUYER DEPOSITS
        assertEq(0, testSilicaV2_1.balanceOf(buyerAddress));

        uint256 buyerDeposit = testSilicaV2_1.reservedPrice();

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), testSilicaV2_1.firstDueDay() - 1);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), testSilicaV2_1.firstDueDay());

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), testSilicaV2_1.firstDueDay() + 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(testSilicaV2_1.getDayOfDefault(), testSilicaV2_1.firstDueDay());
        assertEq(testSilicaV2_1.getRewardDeliveredSoFar(), testSilicaV2_1.initialCollateral());

        //ATTN: These values are set to 0 until settlement is run
        assertEq(testSilicaV2_1.defaultDay(), 0);
        assertEq(testSilicaV2_1.rewardDelivered(), 0);
    }

    function testGetStatusDefaultedMiddleOfContract() public {
        //BUYER DEPOSITS
        assertEq(0, testSilicaV2_1.balanceOf(buyerAddress));

        uint256 buyerDeposit = testSilicaV2_1.reservedPrice();

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), testSilicaV2_1.firstDueDay() - 1);

        for (uint32 day = testSilicaV2_1.firstDueDay(); day < lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertEq(
                rewardToken.balanceOf(address(testSilicaV2_1)),
                TestHelpers.getContractBalanceOnDay(address(testSilicaV2_1), address(rewardTokenOracle))
            );

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay + 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));

        assertEq(testSilicaV2_1.getDayOfDefault(), lastDueDay);
        assertEq(testSilicaV2_1.rewardDelivered(), 0);

        //@TODO: why does this not match?
        // assertEq(testSilicaV2_1.getRewardDeliveredSoFar(),
        // TestHelpers.getTotalRewardDeliveredWhenDefault(address(testSilicaV2_1), address(rewardTokenOracle), testSilicaV2_1.getDayOfDefault(), 40)
        // );
    }

    function testGetStatusFinished() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = 4242424;

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
            if (day > 42) {
                // (status, defaultDay, rewardDelivered) = testSilicaV2_1.getStatus();
                assertEq(
                    rewardToken.balanceOf(address(testSilicaV2_1)),
                    TestHelpers.getContractBalanceOnDay(address(testSilicaV2_1), address(rewardTokenOracle))
                );
            }

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 45);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Finished));
        assertEq(testSilicaV2_1.defaultDay(), 0);
        assertEq(testSilicaV2_1.getDayOfDefault(), 0);

        assertEq(testSilicaV2_1.rewardDelivered(), 0);

        assertEq(
            testSilicaV2_1.getRewardDeliveredSoFar(),
            TestHelpers.getTotalRewardDueWhenFinished(address(testSilicaV2_1), address(rewardTokenOracle), 40)
        );
    }
}
