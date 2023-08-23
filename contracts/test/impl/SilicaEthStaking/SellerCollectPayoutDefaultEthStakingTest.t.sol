pragma solidity 0.8.19;

import "../../base/BaseTest.t.sol";
import {TestHelpers} from "../../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";

import "../../../libraries/math/PayoutMath.sol";

contract SellerCollectPayoutDefaultEthStaking is BaseTest {
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

    function testSellerCollectPayoutDefault() public {
        uint256 buyer1UpfrontPayment = (defaultStakingReservedPrice * 2) / 3; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = (buyer1UpfrontPayment * defaultStakingAmount) / defaultStakingReservedPrice;
        uint256 buyer2UpfrontPayment = defaultStakingReservedPrice / 3; // 1/3 of ressource amount
        uint256 buyer2MintedAmount = (buyer2UpfrontPayment * defaultStakingAmount) / defaultStakingReservedPrice;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment + buyer2UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        uint256 rewardExcess = 420000;
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setBalance(buyer2Address, buyer2MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount + buyer2MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        silicaEthStaking.setResourceAmount(buyer1MintedAmount + buyer2MintedAmount);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        cheats.startPrank(address(silicaEthStaking));
        rewardDelivered = defaultStakingInitialCollateral;
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral + rewardExcess);
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(
            rewardDue,
            (defaultStakingBaseReward * (buyer1MintedAmount + buyer2MintedAmount)) /
                (10**(MasterSilicaEthStaking.decimals())) -
                rewardExcess
        );
        paymentToken.getFaucet(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        cheats.stopPrank();
        assertEq(silicaEthStaking.getDayOfDefault(), defaultFirstDueDay);
        assertEq(uint8(silicaEthStaking.getStatus()), 3);

        uint256 sellerRewardBalanceBeforePayout = stakingRewardToken.balanceOf(sellerAddress);
        uint256 sellerPaymentBalanceBeforePayout = paymentToken.balanceOf(sellerAddress);

        cheats.startPrank(sellerAddress);
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.stopPrank();
        assertEq(stakingRewardToken.balanceOf(sellerAddress), sellerRewardBalanceBeforePayout + rewardExcess);
        uint256 totalAmountOfDepositsRequired = silicaEthStaking.lastDueDay() + 1 - silicaEthStaking.firstDueDay();
        uint256 haircut = PayoutMath._getHaircut(
            silicaEthStaking.getDayOfDefault() - silicaEthStaking.firstDueDay(),
            totalAmountOfDepositsRequired
        );
        assertEq(
            paymentToken.balanceOf(sellerAddress),
            sellerPaymentBalanceBeforePayout + PayoutMath._getRewardPayoutToSellerOnDefault(totalUpfrontPayment, haircut)
        );
        assertEq(stakingRewardToken.balanceOf(address(silicaEthStaking)), rewardDelivered);
        assertEq(
            paymentToken.balanceOf(address(silicaEthStaking)),
            totalUpfrontPayment - PayoutMath._getRewardPayoutToSellerOnDefault(totalUpfrontPayment, haircut)
        );
    }

    function testSellerCollectPayoutDefaultTwice() public {
        uint256 buyer1UpfrontPayment = (defaultStakingReservedPrice * 2) / 3; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = (buyer1UpfrontPayment * defaultStakingAmount) / defaultStakingReservedPrice;
        uint256 buyer2UpfrontPayment = defaultStakingReservedPrice / 3; // 1/3 of ressource amount
        uint256 buyer2MintedAmount = (buyer2UpfrontPayment * defaultStakingAmount) / defaultStakingReservedPrice;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment + buyer2UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        uint256 rewardExcess = 420000;
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setBalance(buyer2Address, buyer2MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount + buyer2MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        silicaEthStaking.setResourceAmount(buyer1MintedAmount + buyer2MintedAmount);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        cheats.startPrank(address(silicaEthStaking));
        rewardDelivered = defaultStakingInitialCollateral;
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral + rewardExcess);
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(
            rewardDue,
            (defaultStakingBaseReward * (buyer1MintedAmount + buyer2MintedAmount)) /
                (10**(MasterSilicaEthStaking.decimals())) -
                rewardExcess
        );
        paymentToken.getFaucet(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        cheats.stopPrank();

        cheats.startPrank(sellerAddress);
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.expectRevert("Payout already collected");
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.stopPrank();
    }

    function testNotSellerCollectPayoutDefault() public {
        uint256 buyer1UpfrontPayment = (defaultStakingReservedPrice * 2) / 3; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = (buyer1UpfrontPayment * defaultStakingAmount) / defaultStakingReservedPrice;
        uint256 buyer2UpfrontPayment = defaultStakingReservedPrice / 3; // 1/3 of ressource amount
        uint256 buyer2MintedAmount = (buyer2UpfrontPayment * defaultStakingAmount) / defaultStakingReservedPrice;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment + buyer2UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        uint256 rewardExcess = 420000;
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setBalance(buyer2Address, buyer2MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount + buyer2MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        silicaEthStaking.setResourceAmount(buyer1MintedAmount + buyer2MintedAmount);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        cheats.startPrank(address(silicaEthStaking));
        rewardDelivered = defaultStakingInitialCollateral;
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral + rewardExcess);
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(
            rewardDue,
            (defaultStakingBaseReward * (buyer1MintedAmount + buyer2MintedAmount)) /
                (10**(MasterSilicaEthStaking.decimals())) -
                rewardExcess
        );
        paymentToken.getFaucet(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        cheats.stopPrank();

        address fakeSeller = address(42);
        cheats.startPrank(fakeSeller);
        cheats.expectRevert("Not Owner");
        silicaEthStaking.sellerCollectPayoutDefault();
    }

    function testSellerCollectPayoutDefaultWhenOpen() public {
        uint256 buyer1UpfrontPayment = defaultStakingReservedPrice; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = defaultStakingAmount;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
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
        cheats.startPrank(sellerAddress);
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 0);
        cheats.expectRevert("Not Defaulted");
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.stopPrank();
    }

    function testSellerCollectPayoutDefaultWhenExpired() public {
        uint256 rewardDue;
        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, 0);

        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        cheats.stopPrank();
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Expired));
        cheats.startPrank(sellerAddress);
        cheats.expectRevert("Not Defaulted");
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.stopPrank();
    }

    function testSellerCollectPayoutDefaultWhenRunning() public {
        uint256 buyer1UpfrontPayment = defaultStakingReservedPrice; // 2/3 of ressource amount
        uint256 buyer1MintedAmount = defaultStakingAmount;
        uint256 totalUpfrontPayment = buyer1UpfrontPayment;
        uint256 rewardDelivered;
        uint256 rewardDue;
        silicaEthStaking.setBalance(buyer1Address, buyer1MintedAmount);
        silicaEthStaking.setTotalSupply(buyer1MintedAmount);
        silicaEthStaking.setTotalUpfrontPayment(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
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
        cheats.startPrank(sellerAddress);
        cheats.expectRevert("Not Defaulted");
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.stopPrank();
    }

    function testSellerCollectPayoutDefaultWhenFinished() public {
        //BUYER DEPOSITS
        uint256 reservedPrice = silicaEthStaking.getReservedPrice();
        uint256 buyerDeposit = defaultStakingReservedPrice;
        silicaEthStaking.setResourceAmount(defaultStakingAmount);
        silicaEthStaking.setReservedPrice(defaultStakingReservedPrice);
        silicaEthStaking.setInitialCollateral(defaultStakingInitialCollateral);
        reservedPrice = silicaEthStaking.getReservedPrice();

        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        cheats.stopPrank();

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();

        cheats.startPrank(sellerAddress);
        for (uint32 day = defaultFirstDueDay - 1; day <= defaultLastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = silicaEthStaking.getRewardDueNextOracleUpdate();
            stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
            stakingRewardToken.transfer(address(silicaEthStaking), rewardDueNextOracleUpdate);
        }
        cheats.stopPrank();
        updateOracleEthStaking(address(oracleEthStaking), defaultLastDueDay + 1, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Finished));

        cheats.startPrank(sellerAddress);
        cheats.expectRevert("Not Defaulted");
        silicaEthStaking.sellerCollectPayoutDefault();
        cheats.stopPrank();
    }
}
