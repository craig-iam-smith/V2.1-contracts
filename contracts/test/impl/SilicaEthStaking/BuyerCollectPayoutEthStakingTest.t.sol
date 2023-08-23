pragma solidity 0.8.19;

import "../../base/BaseTest.t.sol";
import {TestHelpers} from "../../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";

import "../../../libraries/math/PayoutMath.sol";

contract BuyerCollectPayoutEthStaking is BaseTest {
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
        defaultOracleStakingEntry.timestamp = uint256((defaultFirstDueDay - 1) * 24 * 60 * 60);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        cheats.stopPrank();
    }

    function testBuyersCollectPayoutOnFinishedContractWithExcess() public {
        uint256 buyer1UpfrontPayment = defaultStakingReservedPrice; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = defaultStakingAmount;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        cheats.startPrank(address(silicaEthStaking));
        rewardDelivered = defaultStakingInitialCollateral;
        stakingRewardToken.getFaucet(
            defaultStakingInitialCollateral +
                (5 * (defaultStakingBaseReward * buyer1MintedAmount)) /
                (10**(MasterSilicaEthStaking.decimals())) +
                1
        );
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, 0);

        paymentToken.getFaucet(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 2, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 3, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 4, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 5, defaultOracleStakingEntry);
        cheats.stopPrank();
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 4);
        cheats.startPrank(buyer1Address);
        silicaEthStaking.buyerCollectPayout();
        assertEq(
            stakingRewardToken.balanceOf(address(buyer1Address)),
            (5 * (defaultStakingBaseReward * buyer1MintedAmount)) / (10**(MasterSilicaEthStaking.decimals()))
        );
        cheats.stopPrank();
    }

    function testBuyersCollectPayoutOnFinishedContractWithoutExcess() public {
        uint256 buyer1UpfrontPayment = defaultStakingReservedPrice; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = defaultStakingAmount;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        cheats.startPrank(address(silicaEthStaking));
        rewardDelivered = defaultStakingInitialCollateral;
        stakingRewardToken.getFaucet(
            defaultStakingInitialCollateral +
                (5 * (defaultStakingBaseReward * buyer1MintedAmount)) /
                (10**(MasterSilicaEthStaking.decimals()))
        );
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, 0);

        paymentToken.getFaucet(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 2, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 3, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 4, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 5, defaultOracleStakingEntry);
        cheats.stopPrank();
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 4);
        cheats.startPrank(buyer1Address);
        silicaEthStaking.buyerCollectPayout();
        assertEq(
            stakingRewardToken.balanceOf(address(buyer1Address)),
            (5 * (defaultStakingBaseReward * buyer1MintedAmount)) / (10**(MasterSilicaEthStaking.decimals()))
        );
        cheats.stopPrank();
    }

    function testNonBuyerTriesToCollectPayoutOnFinishedContract() public {
        uint256 buyer1UpfrontPayment = defaultStakingReservedPrice; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = defaultStakingAmount;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        cheats.startPrank(address(silicaEthStaking));
        rewardDelivered = defaultStakingInitialCollateral;
        stakingRewardToken.getFaucet(
            defaultStakingInitialCollateral +
                (5 * (defaultStakingBaseReward * buyer1MintedAmount)) /
                (10**(MasterSilicaEthStaking.decimals()))
        );
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, 0);

        paymentToken.getFaucet(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 2, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 3, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 4, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 5, defaultOracleStakingEntry);
        cheats.stopPrank();
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 4);
        address fakeBuyer = address(42);
        cheats.startPrank(fakeBuyer);
        cheats.expectRevert("Not Buyer");
        silicaEthStaking.buyerCollectPayout();
        cheats.stopPrank();
    }

    function testBuyerTriesToCollectPayoutTwiceOnFinishedContract() public {
        uint256 buyer1UpfrontPayment = defaultStakingReservedPrice; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = defaultStakingAmount;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        cheats.startPrank(address(silicaEthStaking));
        rewardDelivered = defaultStakingInitialCollateral;
        stakingRewardToken.getFaucet(
            defaultStakingInitialCollateral +
                (5 * (defaultStakingBaseReward * buyer1MintedAmount)) /
                (10**(MasterSilicaEthStaking.decimals()))
        );
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, 0);

        paymentToken.getFaucet(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 2, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 3, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 4, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 5, defaultOracleStakingEntry);
        cheats.stopPrank();
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 4);
        cheats.startPrank(buyer1Address);
        silicaEthStaking.buyerCollectPayout();
        assertEq(
            stakingRewardToken.balanceOf(address(buyer1Address)),
            (5 * (defaultStakingBaseReward * buyer1MintedAmount)) / (10**(MasterSilicaEthStaking.decimals()))
        );
        cheats.expectRevert("Not Buyer");
        silicaEthStaking.buyerCollectPayout();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutWhenOpen() public {
        uint256 buyer1UpfrontPayment = defaultStakingReservedPrice; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = defaultStakingAmount;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        silicaEthStaking.setFirstDueDay(uint32(defaultFirstDueDay + 1));
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        cheats.startPrank(address(silicaEthStaking));
        rewardDelivered = defaultStakingInitialCollateral;
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, 0);

        paymentToken.getFaucet(totalUpfrontPayment);
        cheats.stopPrank();
        cheats.startPrank(buyer1Address);
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 0);
        cheats.expectRevert("Not Finished");
        silicaEthStaking.buyerCollectPayout();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutWhenExpired() public {
        uint256 rewardDue;
        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, 0);

        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        cheats.stopPrank();
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 2);
        cheats.startPrank(buyer1Address);
        cheats.expectRevert("Not Finished");
        silicaEthStaking.buyerCollectPayout();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutWhenRunning() public {
        uint256 buyer1UpfrontPayment = defaultStakingReservedPrice; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = defaultStakingAmount;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        cheats.startPrank(address(silicaEthStaking));
        rewardDelivered = defaultStakingInitialCollateral;
        stakingRewardToken.getFaucet(
            defaultStakingInitialCollateral + (defaultStakingBaseReward * buyer1MintedAmount) / (10**(MasterSilicaEthStaking.decimals()))
        );
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, 0);

        paymentToken.getFaucet(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        cheats.stopPrank();
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 1);
        cheats.startPrank(buyer1Address);
        cheats.expectRevert("Not Finished");
        silicaEthStaking.buyerCollectPayout();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutWhenDefault() public {
        uint256 buyer1UpfrontPayment = (defaultStakingReservedPrice * 2) / 3; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = (buyer1UpfrontPayment * defaultStakingAmount) / defaultStakingReservedPrice;
        uint256 buyer2UpfrontPayment = defaultStakingReservedPrice / 3; // 1/3 of ressource amount
        uint256 buyer2MintedAmount = (buyer2UpfrontPayment * defaultStakingAmount) / defaultStakingReservedPrice;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment + buyer2UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setBalance(buyer2Address, buyer2MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount + buyer2MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        silicaEthStaking.setResourceAmount(buyer1MintedAmount + buyer2MintedAmount);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        cheats.startPrank(address(silicaEthStaking));
        rewardDelivered = defaultStakingInitialCollateral;
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(
            rewardDue,
            (defaultStakingBaseReward * (buyer1MintedAmount + buyer2MintedAmount)) / (10**(MasterSilicaEthStaking.decimals()))
        );

        paymentToken.getFaucet(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        cheats.stopPrank();

        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 3);
        cheats.startPrank(buyer1Address);
        cheats.expectRevert("Not Finished");
        silicaEthStaking.buyerCollectPayout();
        cheats.stopPrank();
    }
}
