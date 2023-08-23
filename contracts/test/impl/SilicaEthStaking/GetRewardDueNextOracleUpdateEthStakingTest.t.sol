pragma solidity 0.8.19;

import "../../base/BaseTest.t.sol";
import {TestHelpers} from "../../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";

import "../../../libraries/math/PayoutMath.sol";

contract GetRewardDueNextOracleUpdateEthStaking is BaseTest {
    using SilicaV2_1Storage for SilicaEthStaking;

    address buyer1Address = address(12345);
    address buyer2Address = address(6789);

    SilicaEthStaking silicaEthStaking = new SilicaEthStaking();

    function setUp() public override {
        super.setUp();
        defaultLastDueDay = defaultFirstDueDay + 20; // This is need for to work testCollateralReleaseAndNoDefaultCallEdgeCase
        //SELLER CREATES SILICA
        cheats.startPrank(sellerAddress);
        silicaEthStaking = new SilicaEthStaking();
        silicaEthStaking.setRewardToken(address(stakingRewardToken));
        silicaEthStaking.setPaymentToken(address(paymentToken));
        silicaEthStaking.setOracleRegistry(address(oracleRegistry));
        silicaEthStaking.setOwner(address(sellerAddress));
        silicaEthStaking.setFirstDueDay(uint32(defaultFirstDueDay));
        silicaEthStaking.setLastDueDay(uint32(defaultLastDueDay));
        silicaEthStaking.setResourceAmount(defaultStakingAmount);
        silicaEthStaking.setReservedPrice(defaultStakingReservedPrice);
        silicaEthStaking.setInitialCollateral(defaultStakingInitialCollateral);
        defaultOracleStakingEntry.baseRewardPerIncrementPerDay = uint256(185000000000000);
        defaultOracleStakingEntry.timestamp = uint256((defaultFirstDueDay - 2) * 24 * 60 * 60);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 2, defaultOracleStakingEntry);
        cheats.stopPrank();
        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        cheats.stopPrank();
    }

    function testRewardDueIsZeroOnDeadDay() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);

        uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();

        assertEq(rewardDueNextOracleUpdate, 0);
    }

    function testWhenRunning() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);

        cheats.startPrank(sellerAddress);
        for (uint32 day = defaultFirstDueDay; day <= defaultLastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);
            assertEq(
                stakingRewardToken.balanceOf(address(silicaEthStaking)),
                TestHelpers.getExpectedContractBalanceOnAGivenDayEthStaking(
                    address(silicaEthStaking),
                    address(oracleEthStaking),
                    oracleEthStaking.getLastIndexedDay() - 1
                )
            );

            uint256 initialCollateral = silicaEthStaking.initialCollateral();
            uint256 initialCollateralAfterRelease = (initialCollateral * silicaEthStaking.totalSupply()) /
                silicaEthStaking.resourceAmount();
            uint256 numDeposits = defaultLastDueDay + 1 - defaultFirstDueDay;
            uint256 initCollateralReleaseDay = numDeposits % 4 > 0
                ? defaultFirstDueDay + 1 + (numDeposits / 4)
                : defaultFirstDueDay + (numDeposits / 4);
            uint256 finalCollateralReleaseDay = numDeposits % 2 > 0
                ? defaultFirstDueDay + 1 + (numDeposits / 2)
                : defaultFirstDueDay + (numDeposits / 2);

            uint256 collateralLocked = initialCollateralAfterRelease;

            if (lastIndexedDay >= finalCollateralReleaseDay) {
                collateralLocked = 0;
            }
            if (lastIndexedDay >= initCollateralReleaseDay) {
                collateralLocked = (initialCollateralAfterRelease * 3) / 4;
            }

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
            stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
            stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        }
        cheats.stopPrank();
    }

    function testWhenOpen() public {
        uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();

        assertEq(rewardDueNextOracleUpdate, 0);
    }

    function testWhenExpired() public {
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);

        uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();

        assertEq(rewardDueNextOracleUpdate, 0);
    }

    function testWhenDefaultedAFewDaysBeforeFinishedAndSavingTheContractForTheNextUpdate() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);

        cheats.startPrank(sellerAddress);
        uint256 rewardDueNextOracleUpdate;
        for (uint32 day = defaultFirstDueDay; day <= defaultLastDueDay - 4; day++) {
            //ADVANCE TO NEXT DAY
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);
            assertEq(
                stakingRewardToken.balanceOf(address(silicaEthStaking)),
                TestHelpers.getExpectedContractBalanceOnAGivenDayEthStaking(
                    address(silicaEthStaking),
                    address(oracleEthStaking),
                    oracleEthStaking.getLastIndexedDay() - 1
                )
            );

            uint256 initialCollateral = silicaEthStaking.initialCollateral();
            uint256 initialCollateralAfterRelease = (initialCollateral * silicaEthStaking.totalSupply()) /
                silicaEthStaking.resourceAmount();
            uint256 numDeposits = defaultLastDueDay + 1 - defaultFirstDueDay;
            uint256 initCollateralReleaseDay = numDeposits % 4 > 0
                ? defaultFirstDueDay + 1 + (numDeposits / 4)
                : defaultFirstDueDay + (numDeposits / 4);
            uint256 finalCollateralReleaseDay = numDeposits % 2 > 0
                ? defaultFirstDueDay + 1 + (numDeposits / 2)
                : defaultFirstDueDay + (numDeposits / 2);

            uint256 collateralLocked = initialCollateralAfterRelease;

            if (lastIndexedDay >= finalCollateralReleaseDay) {
                collateralLocked = 0;
            }
            if (lastIndexedDay >= initCollateralReleaseDay) {
                collateralLocked = (initialCollateralAfterRelease * 3) / 4;
            }

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
            stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
            stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        }

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay - 3, defaultOracleStakingEntry);
        rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay - 2, defaultOracleStakingEntry);
        rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();

        assertEq(
            rewardDueNextOracleUpdate,
            TestHelpers.getExpectedContractBalanceOnAGivenDayEthStaking(
                address(silicaEthStaking),
                address(oracleEthStaking),
                oracleEthStaking.getLastIndexedDay()
            ) - stakingRewardToken.balanceOf(address(silicaEthStaking))
        );
        assertEq(uint8(silicaEthStaking.getStatus()), uint8(SilicaV2_1Types.Status.Defaulted));
        stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
        stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        assertEq(uint8(silicaEthStaking.getStatus()), uint8(SilicaV2_1Types.Status.Running));
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay - 1, defaultOracleStakingEntry);
        assertEq(uint8(silicaEthStaking.getStatus()), uint8(SilicaV2_1Types.Status.Running));
        cheats.stopPrank();
    }

    function testWhenDefaultedSetInStorage() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);

        cheats.startPrank(sellerAddress);
        uint256 rewardDueNextOracleUpdate;
        for (uint32 day = defaultFirstDueDay; day <= defaultLastDueDay - 4; day++) {
            //ADVANCE TO NEXT DAY
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);
            assertEq(
                stakingRewardToken.balanceOf(address(silicaEthStaking)),
                TestHelpers.getExpectedContractBalanceOnAGivenDayEthStaking(
                    address(silicaEthStaking),
                    address(oracleEthStaking),
                    oracleEthStaking.getLastIndexedDay() - 1
                )
            );

            uint256 initialCollateral = silicaEthStaking.initialCollateral();
            uint256 initialCollateralAfterRelease = (initialCollateral * silicaEthStaking.totalSupply()) /
                silicaEthStaking.resourceAmount();
            uint256 numDeposits = defaultLastDueDay + 1 - defaultFirstDueDay;
            uint256 initCollateralReleaseDay = numDeposits % 4 > 0
                ? defaultFirstDueDay + 1 + (numDeposits / 4)
                : defaultFirstDueDay + (numDeposits / 4);
            uint256 finalCollateralReleaseDay = numDeposits % 2 > 0
                ? defaultFirstDueDay + 1 + (numDeposits / 2)
                : defaultFirstDueDay + (numDeposits / 2);

            uint256 collateralLocked = initialCollateralAfterRelease;

            if (lastIndexedDay >= finalCollateralReleaseDay) {
                collateralLocked = 0;
            }
            if (lastIndexedDay >= initCollateralReleaseDay) {
                collateralLocked = (initialCollateralAfterRelease * 3) / 4;
            }

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
            stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
            stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        }
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay - 3, defaultOracleStakingEntry);
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay - 2, defaultOracleStakingEntry);

        //SETTING THE DEFAULT IN STORAGE
        cheats.prank(buyerAddress);
        silicaEthStaking.buyerCollectPayoutOnDefault();

        rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDueNextOracleUpdate, 0);
    }

    function testWhenFinished() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);

        cheats.startPrank(sellerAddress);
        for (uint32 day = defaultFirstDueDay; day <= defaultLastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);
            assertEq(
                stakingRewardToken.balanceOf(address(silicaEthStaking)),
                TestHelpers.getExpectedContractBalanceOnAGivenDayEthStaking(
                    address(silicaEthStaking),
                    address(oracleEthStaking),
                    oracleEthStaking.getLastIndexedDay() - 1
                )
            );

            uint256 initialCollateral = silicaEthStaking.initialCollateral();
            uint256 initialCollateralAfterRelease = (initialCollateral * silicaEthStaking.totalSupply()) /
                silicaEthStaking.resourceAmount();
            uint256 numDeposits = defaultLastDueDay + 1 - defaultFirstDueDay;
            uint256 initCollateralReleaseDay = numDeposits % 4 > 0
                ? defaultFirstDueDay + 1 + (numDeposits / 4)
                : defaultFirstDueDay + (numDeposits / 4);
            uint256 finalCollateralReleaseDay = numDeposits % 2 > 0
                ? defaultFirstDueDay + 1 + (numDeposits / 2)
                : defaultFirstDueDay + (numDeposits / 2);

            uint256 collateralLocked = initialCollateralAfterRelease;

            if (lastIndexedDay >= finalCollateralReleaseDay) {
                collateralLocked = 0;
            }
            if (lastIndexedDay >= initCollateralReleaseDay) {
                collateralLocked = (initialCollateralAfterRelease * 3) / 4;
            }

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
            stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
            stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        }
        cheats.stopPrank();
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay + 1, defaultOracleStakingEntry);
        assertEq(silicaEthStaking.getRewardDueNextOracleUpdate(), 0);
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay + 2, defaultOracleStakingEntry);
        assertEq(silicaEthStaking.getRewardDueNextOracleUpdate(), 0);
    }

    function testCollateralReleaseAndNoDefaultCallEdgeCase() public {
        //BUYER DEPOSITS
        uint256 reservedPrice = silicaEthStaking.reservedPrice();
        uint256 buyerDeposit = reservedPrice;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();

        //Calculate collateral release days
        uint32 numOfDepositsRequired = defaultLastDueDay + 1 - defaultFirstDueDay;
        uint32 initCollateralReleaseDay = numOfDepositsRequired % 4 > 0
            ? defaultFirstDueDay + 1 + (numOfDepositsRequired / 4)
            : defaultFirstDueDay + (numOfDepositsRequired / 4);
        uint32 finalCollateralReleaseDay = numOfDepositsRequired % 2 > 0
            ? defaultFirstDueDay + 1 + (numOfDepositsRequired / 2)
            : defaultFirstDueDay + (numOfDepositsRequired / 2);

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);

        for (uint32 day = defaultFirstDueDay; day < initCollateralReleaseDay - 1; day++) {
            //ADVANCE TO NEXT DAY
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);
            assertEq(uint8(silicaEthStaking.getStatus()), uint8(SilicaV2_1Types.Status.Running));

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            cheats.prank(sellerAddress);
            stakingRewardToken.transfer(address(silicaEthStaking), silicaEthStaking.getRewardDueNextOracleUpdate());
        }

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), initCollateralReleaseDay - 1, defaultOracleStakingEntry);

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), initCollateralReleaseDay, defaultOracleStakingEntry);
        assertEq(uint8(silicaEthStaking.getStatus()), uint8(SilicaV2_1Types.Status.Defaulted));

        //SELLER DEPOSITS REWARD DUE NEXT UPDATE
        cheats.prank(sellerAddress);
        stakingRewardToken.transfer(address(silicaEthStaking), silicaEthStaking.getRewardDueNextOracleUpdate());
        assertEq(uint8(silicaEthStaking.getStatus()), uint8(SilicaV2_1Types.Status.Running));

        for (uint32 day = initCollateralReleaseDay + 1; day < finalCollateralReleaseDay - 1; day++) {
            //ADVANCE TO NEXT DAY
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);
            assertEq(uint8(silicaEthStaking.getStatus()), uint8(SilicaV2_1Types.Status.Running));

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            cheats.prank(sellerAddress);
            stakingRewardToken.transfer(address(silicaEthStaking), silicaEthStaking.getRewardDueNextOracleUpdate());
        }

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), finalCollateralReleaseDay - 1, defaultOracleStakingEntry);

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), finalCollateralReleaseDay, defaultOracleStakingEntry);
        assertEq(uint8(silicaEthStaking.getStatus()), uint8(SilicaV2_1Types.Status.Defaulted));

        //SELLER DEPOSITS REWARD DUE NEXT UPDATE
        cheats.prank(sellerAddress);
        stakingRewardToken.transfer(address(silicaEthStaking), silicaEthStaking.getRewardDueNextOracleUpdate());
        assertEq(uint8(silicaEthStaking.getStatus()), uint8(SilicaV2_1Types.Status.Running));
    }
}
