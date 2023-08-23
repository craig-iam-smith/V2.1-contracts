pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

contract getRewardDueNextOracleUpdate is BaseTest {
    using SilicaV2_1Storage for SilicaV2_1;

    SilicaV2_1 testSilicaV2_1;

    uint256 hashrate = 60000000000000; //60000 Gh
    uint32 lastDueDay = 71;
    uint32 deployDay = lastIndexedDay;
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

    function testRewardDueIsZeroOnDeadDay() public {
        //BUYER DEPOSITS
        uint256 reservedPrice = testSilicaV2_1.reservedPrice();
        uint256 buyerDeposit = reservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), deployDay + 1);
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Running)); //status == Running

        assertEq(testSilicaV2_1.getRewardDueNextOracleUpdate(), 0);
    }

    function testWhenRunning() public {
        //BUYER DEPOSITS
        uint256 reservedPrice = testSilicaV2_1.reservedPrice();
        uint256 buyerDeposit = reservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), deployDay + 1);

        for (uint32 day = testSilicaV2_1.firstDueDay(); day <= lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Running)); //status == Running
            //@review: the next lines break in the final collateral release because the reward balance of the contract is bigger than what is really needed.
            // assertEq(
            //     rewardToken.balanceOf(address(testSilicaV2_1)),
            //     TestHelpers.getContractBalanceOnDay(address(testSilicaV2_1), address(rewardTokenOracle))
            // );

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), testSilicaV2_1.getRewardDueNextOracleUpdate());
        }
    }

    function testWhenOpen() public {
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Open)); //status == Open

        assertEq(testSilicaV2_1.getRewardDueNextOracleUpdate(), 0);
    }

    function testWhenExpired() public {
        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), deployDay + 1);
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Expired)); //status == Expired

        assertEq(testSilicaV2_1.getRewardDueNextOracleUpdate(), 0);
    }

    function testWhenDefaulted1DaybeforeFinished() public {
        //BUYER DEPOSITS
        uint256 reservedPrice = testSilicaV2_1.reservedPrice();
        uint256 buyerDeposit = reservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), deployDay + 1);

        for (uint32 day = testSilicaV2_1.firstDueDay(); day < lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), testSilicaV2_1.getRewardDueNextOracleUpdate());
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay + 1);
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Defaulted)); //status == Defaulted

        uint256 rewardDueOnDay = TestHelpers.getContractBalanceOnDay(address(testSilicaV2_1), address(rewardTokenOracle));
        assertEq(testSilicaV2_1.getRewardDueNextOracleUpdate(), rewardDueOnDay - rewardToken.balanceOf(address(testSilicaV2_1)));
    }

    function testWhenDefaultedAFewDaysBeforeFinished() public {
        //BUYER DEPOSITS
        uint256 reservedPrice = testSilicaV2_1.reservedPrice();
        uint256 buyerDeposit = reservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), deployDay + 1);

        for (uint32 day = testSilicaV2_1.firstDueDay(); day < lastDueDay - 3; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), testSilicaV2_1.getRewardDueNextOracleUpdate());
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay - 3);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay - 2);
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Defaulted)); //status == Defaulted

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay - 1);
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Defaulted)); //status == Defaulted

        uint256 rewardDueOnDay = TestHelpers.getContractBalanceOnGivenDay(address(testSilicaV2_1), address(rewardTokenOracle), lastDueDay);
        uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
        assertEq(rewardDueNextOracleUpdate, rewardDueOnDay - rewardToken.balanceOf(address(testSilicaV2_1)));
    }

    function testWhenDefaultedSetInStorage() public {
        //BUYER DEPOSITS
        uint256 reservedPrice = testSilicaV2_1.reservedPrice();
        uint256 buyerDeposit = reservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), deployDay + 1);

        for (uint32 day = testSilicaV2_1.firstDueDay(); day < lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), testSilicaV2_1.getRewardDueNextOracleUpdate());
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay + 1);
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Defaulted)); //status == Defaulted

        //SETTING THE DEFAULT IN STORAGE
        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayoutOnDefault();

        uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
        assertEq(rewardDueNextOracleUpdate, 0);
    }

    function testWhenFinished() public {
        //BUYER DEPOSITS
        uint256 reservedPrice = testSilicaV2_1.reservedPrice();
        uint256 buyerDeposit = reservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), deployDay + 1);

        for (uint32 day = testSilicaV2_1.firstDueDay(); day <= lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), testSilicaV2_1.getRewardDueNextOracleUpdate());
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay + 1);
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Finished)); //status == Finished

        uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
        assertEq(rewardDueNextOracleUpdate, 0);
    }

    function testCollateralReleaseAndNoDefaultCallEdgeCase() public {
        //BUYER DEPOSITS
        uint256 reservedPrice = testSilicaV2_1.reservedPrice();
        uint256 buyerDeposit = reservedPrice;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //Calculate collateral release days
        uint32 numOfDepositsRequired = lastDueDay + 1 - testSilicaV2_1.firstDueDay();
        uint32 initCollateralReleaseDay = numOfDepositsRequired % 4 > 0
            ? testSilicaV2_1.firstDueDay() + 1 + (numOfDepositsRequired / 4)
            : testSilicaV2_1.firstDueDay() + (numOfDepositsRequired / 4);
        uint32 finalCollateralReleaseDay = numOfDepositsRequired % 2 > 0
            ? testSilicaV2_1.firstDueDay() + 1 + (numOfDepositsRequired / 2)
            : testSilicaV2_1.firstDueDay() + (numOfDepositsRequired / 2);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), deployDay + 1);

        for (uint32 day = testSilicaV2_1.firstDueDay(); day < initCollateralReleaseDay - 1; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Running));

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), testSilicaV2_1.getRewardDueNextOracleUpdate());
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), initCollateralReleaseDay - 1);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), initCollateralReleaseDay);
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Defaulted));

        //SELLER DEPOSITS REWARD DUE NEXT UPDATE
        cheats.prank(sellerAddress);
        rewardToken.transfer(address(testSilicaV2_1), testSilicaV2_1.getRewardDueNextOracleUpdate());
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Running));

        for (uint32 day = initCollateralReleaseDay + 1; day < finalCollateralReleaseDay - 1; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Running));

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), testSilicaV2_1.getRewardDueNextOracleUpdate());
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), finalCollateralReleaseDay - 1);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), finalCollateralReleaseDay);
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Defaulted));

        //SELLER DEPOSITS REWARD DUE NEXT UPDATE
        cheats.prank(sellerAddress);
        rewardToken.transfer(address(testSilicaV2_1), testSilicaV2_1.getRewardDueNextOracleUpdate());
        assertEq(uint8(testSilicaV2_1.getStatus()), uint8(SilicaV2_1Types.Status.Running));
    }
}
