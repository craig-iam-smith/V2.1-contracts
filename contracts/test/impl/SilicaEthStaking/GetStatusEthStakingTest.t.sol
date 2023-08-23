pragma solidity 0.8.19;

import "../../base/BaseTest.t.sol";
import {TestHelpers} from "../../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";
import "../../../libraries/math/PayoutMath.sol";

contract GetStatusEthStaking is BaseTest {
    using SilicaV2_1Storage for SilicaEthStaking;

    address buyer1Address = address(12345);
    address buyer2Address = address(6789);

    SilicaEthStaking silicaEthStaking = new SilicaEthStaking();

    function setUp() public override {
        super.setUp();
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
    }

    function testGetStatusOpen() public {
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Open));
        uint256 buyerDepositAmount = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.approve(address(silicaEthStaking), buyerDepositAmount);
        silicaEthStaking.deposit(buyerDepositAmount);
        cheats.stopPrank();

        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Open));
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        assertFalse(uint256(silicaEthStaking.getStatus()) == uint256(SilicaV2_1Types.Status.Open));
    }

    function testGetStatusExpired() public {
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Expired));

        cheats.startPrank(sellerAddress);
        silicaEthStaking.sellerCollectPayoutExpired();
        cheats.stopPrank();

        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Expired));
    }

    function testGetStatusRunning() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();

        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        cheats.startPrank(sellerAddress);
        for (uint32 day = defaultFirstDueDay; day <= defaultLastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);
            assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Running));

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
            stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
            stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        }
        cheats.stopPrank();
    }

    function testGetStatusDefaultedFirstDueDaySellerCollectsPayoutFirst() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice;

        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        cheats.stopPrank();
        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), defaultFirstDueDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), silicaEthStaking.initialCollateral());

        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);
        // The values should stay the same with a oracle update
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 2, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), defaultFirstDueDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), silicaEthStaking.initialCollateral());

        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        cheats.startPrank(sellerAddress);
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), defaultFirstDueDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), silicaEthStaking.initialCollateral());

        //ATTN: These values should be set
        assertEq(silicaEthStaking.defaultDay(), defaultFirstDueDay);
        assertEq(silicaEthStaking.rewardDelivered(), silicaEthStaking.initialCollateral());

        cheats.startPrank(buyerAddress);
        silicaEthStaking.buyerCollectPayoutOnDefault();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), defaultFirstDueDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), silicaEthStaking.initialCollateral());
        assertEq(silicaEthStaking.defaultDay(), defaultFirstDueDay);
        assertEq(silicaEthStaking.rewardDelivered(), silicaEthStaking.initialCollateral());
    }

    function testGetStatusDefaultedFirstDueDayBuyersCollectsPayoutFirst() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice;

        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        cheats.stopPrank();
        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), defaultFirstDueDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), silicaEthStaking.initialCollateral());

        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        // The values should stay the same with a oracle update
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 2, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), defaultFirstDueDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), silicaEthStaking.initialCollateral());

        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        cheats.startPrank(buyerAddress);
        silicaEthStaking.buyerCollectPayoutOnDefault();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), defaultFirstDueDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), silicaEthStaking.initialCollateral());

        //ATTN: These values should be set
        assertEq(silicaEthStaking.defaultDay(), defaultFirstDueDay);
        assertEq(silicaEthStaking.rewardDelivered(), silicaEthStaking.initialCollateral());

        cheats.startPrank(sellerAddress);
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), defaultFirstDueDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), silicaEthStaking.initialCollateral());
        assertEq(silicaEthStaking.defaultDay(), defaultFirstDueDay);
        assertEq(silicaEthStaking.rewardDelivered(), silicaEthStaking.initialCollateral());
    }

    function testGetStatusDefaultedOnInitCollateralReleaseDay() public {
        uint32 numDeposits = defaultLastDueDay + 1 - defaultFirstDueDay;
        uint32 initCollateralReleaseDay = numDeposits % 4 > 0
            ? defaultFirstDueDay + 1 + (numDeposits / 4)
            : defaultFirstDueDay + (numDeposits / 4);

        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice;

        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        cheats.stopPrank();
        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        uint32 lastIndexedDay = oracleEthStaking.getLastIndexedDay();
        cheats.startPrank(sellerAddress);
        for (uint32 day = defaultFirstDueDay; day < initCollateralReleaseDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);
            lastIndexedDay = oracleEthStaking.getLastIndexedDay();

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
            stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
            stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        }
        cheats.stopPrank();
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), initCollateralReleaseDay, defaultOracleStakingEntry);

        uint256 initialCollateralLocked = (defaultStakingInitialCollateral * silicaEthStaking.totalSupply()) /
            silicaEthStaking.resourceAmount();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), initCollateralReleaseDay + 1, defaultOracleStakingEntry);
        uint256 totalRewardDelivered = TestHelpers.getTotalRewardDeliveredWhenDefaultEthStaking(
            address(silicaEthStaking),
            address(oracleEthStaking),
            silicaEthStaking.getDayOfDefault(),
            ((initialCollateralLocked * 3) / 4)
        );
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), initCollateralReleaseDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);
        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        // The values should stay the same with a oracle update
        updateOracleEthStaking(address(oracleEthStaking), initCollateralReleaseDay + 2, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), initCollateralReleaseDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);
        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        cheats.startPrank(sellerAddress);
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), initCollateralReleaseDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);
        //ATTN: These values should be set
        assertEq(silicaEthStaking.defaultDay(), initCollateralReleaseDay);
        assertEq(silicaEthStaking.rewardDelivered(), totalRewardDelivered);
        cheats.startPrank(buyerAddress);
        silicaEthStaking.buyerCollectPayoutOnDefault();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), initCollateralReleaseDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);
        assertEq(silicaEthStaking.defaultDay(), initCollateralReleaseDay);
        assertEq(silicaEthStaking.rewardDelivered(), totalRewardDelivered);
    }

    function testGetStatusDefaultedOnFinalCollateralReleaseDay() public {
        uint32 lastDueDay = uint32(defaultLastDueDay + 1);
        uint32 numDeposits = lastDueDay + 1 - defaultFirstDueDay;
        uint32 finalCollateralReleaseDay = numDeposits % 2 > 0
            ? defaultFirstDueDay + 1 + (numDeposits / 2)
            : defaultFirstDueDay + (numDeposits / 2);

        //BUYER DEPOSITS
        silicaEthStaking.setLastDueDay(uint32(lastDueDay));
        uint256 buyerDeposit = defaultStakingReservedPrice;
        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        cheats.stopPrank();
        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        uint32 lastIndexedDay = oracleEthStaking.getLastIndexedDay();
        cheats.startPrank(sellerAddress);
        for (uint32 day = defaultFirstDueDay; day < finalCollateralReleaseDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);
            lastIndexedDay = oracleEthStaking.getLastIndexedDay();

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
            stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
            stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        }
        cheats.stopPrank();
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), finalCollateralReleaseDay, defaultOracleStakingEntry);

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), finalCollateralReleaseDay + 1, defaultOracleStakingEntry);
        uint256 totalRewardDelivered = TestHelpers.getTotalRewardDeliveredWhenDefaultEthStaking(
            address(silicaEthStaking),
            address(oracleEthStaking),
            silicaEthStaking.getDayOfDefault(),
            0
        );
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), finalCollateralReleaseDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);
        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        // The values should stay the same with a oracle update
        updateOracleEthStaking(address(oracleEthStaking), finalCollateralReleaseDay + 2, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), finalCollateralReleaseDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);
        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        cheats.startPrank(sellerAddress);
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), finalCollateralReleaseDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);
        //ATTN: These values should be set
        assertEq(silicaEthStaking.defaultDay(), finalCollateralReleaseDay);
        assertEq(silicaEthStaking.rewardDelivered(), totalRewardDelivered);
        cheats.startPrank(buyerAddress);
        silicaEthStaking.buyerCollectPayoutOnDefault();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        assertEq(silicaEthStaking.getDayOfDefault(), finalCollateralReleaseDay);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);
        assertEq(silicaEthStaking.defaultDay(), finalCollateralReleaseDay);
        assertEq(silicaEthStaking.rewardDelivered(), totalRewardDelivered);
    }

    function testGetStatusFinishedFirstDueDaySellerCollectsPayoutFirst() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice;

        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        cheats.stopPrank();
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
            lastIndexedDay = oracleEthStaking.getLastIndexedDay();

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
            stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
            stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        }
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay + 1, defaultOracleStakingEntry);

        uint256 totalRewardDelivered = TestHelpers.getTotalRewardDueWhenFinishedEthStaking(
            address(silicaEthStaking),
            address(oracleEthStaking),
            defaultFirstDueDay
        );
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Finished));
        assertEq(silicaEthStaking.getDayOfDefault(), 0);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);

        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.finishDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        // The values should stay the same with a oracle update
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay + 2, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Finished));
        assertEq(silicaEthStaking.getDayOfDefault(), 0);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);

        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.finishDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        cheats.startPrank(sellerAddress);
        silicaEthStaking.sellerCollectPayout();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Finished));
        cheats.expectRevert("contract not defaulted");
        silicaEthStaking.getDayOfDefault();
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);

        //ATTN: These values should be set
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.finishDay(), defaultLastDueDay);
        assertEq(silicaEthStaking.rewardDelivered(), totalRewardDelivered);

        cheats.startPrank(buyerAddress);
        silicaEthStaking.buyerCollectPayout();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Finished));
        cheats.expectRevert("contract not defaulted");
        silicaEthStaking.getDayOfDefault();
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.finishDay(), defaultLastDueDay);
        assertEq(silicaEthStaking.rewardDelivered(), totalRewardDelivered);
    }

    function testGetStatusFinishedFirstDueDayBuyersCollectsPayoutFirst() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = defaultStakingReservedPrice;

        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        cheats.stopPrank();
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
            lastIndexedDay = oracleEthStaking.getLastIndexedDay();

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
            stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
            stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        }
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay + 1, defaultOracleStakingEntry);

        uint256 totalRewardDelivered = TestHelpers.getTotalRewardDueWhenFinishedEthStaking(
            address(silicaEthStaking),
            address(oracleEthStaking),
            defaultFirstDueDay
        );
        
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Finished));
        assertEq(silicaEthStaking.getDayOfDefault(), 0);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);

        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.finishDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        // The values should stay the same with a oracle update
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay + 2, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Finished));
        assertEq(silicaEthStaking.getDayOfDefault(), 0);
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);

        //ATTN: These values are set to 0 until settlement is run
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.finishDay(), 0);
        assertEq(silicaEthStaking.rewardDelivered(), 0);

        cheats.startPrank(buyerAddress);
        silicaEthStaking.buyerCollectPayout();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Finished));

        cheats.expectRevert("contract not defaulted");
        silicaEthStaking.getDayOfDefault();

        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);

        //ATTN: These values should be set
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.finishDay(), defaultLastDueDay);
        assertEq(silicaEthStaking.rewardDelivered(), totalRewardDelivered);

        cheats.startPrank(sellerAddress);
        silicaEthStaking.sellerCollectPayout();
        cheats.stopPrank();

        // The values should stay the same
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Finished));

        cheats.expectRevert("contract not defaulted");
        silicaEthStaking.getDayOfDefault();
        assertEq(silicaEthStaking.getRewardDeliveredSoFar(), totalRewardDelivered);
        assertEq(silicaEthStaking.defaultDay(), 0);
        assertEq(silicaEthStaking.finishDay(), defaultLastDueDay);
        assertEq(silicaEthStaking.rewardDelivered(), totalRewardDelivered);
    }
}
