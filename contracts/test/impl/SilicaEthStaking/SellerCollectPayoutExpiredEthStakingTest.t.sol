pragma solidity 0.8.19;

import "../../base/BaseTest.t.sol";
import {TestHelpers} from "../../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";

import "../../../libraries/math/PayoutMath.sol";

contract SellerCollectPayoutExpiredEthStaking is BaseTest {
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

    function testSellerCollectPayoutExpired() public {
        uint256 rewardDue;
        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, 0);

        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        cheats.stopPrank();
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 2);
        cheats.startPrank(sellerAddress);
        uint256 sellerRewardBalanceBeforePayout = stakingRewardToken.balanceOf(sellerAddress);
        silicaEthStaking.sellerCollectPayoutExpired();
        assertEq(stakingRewardToken.balanceOf(sellerAddress), sellerRewardBalanceBeforePayout + defaultStakingInitialCollateral);
        assertEq(stakingRewardToken.balanceOf(address(silicaEthStaking)), 0);
        cheats.stopPrank();
    }

    function testFakeSellerCollectPayoutExpired() public {
        uint256 rewardDue;
        cheats.startPrank(address(silicaEthStaking));
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, 0);

        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        cheats.stopPrank();
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 2);
        address fakeSeller = address(42);
        cheats.startPrank(fakeSeller);
        cheats.expectRevert("Not Owner");
        silicaEthStaking.sellerCollectPayoutExpired();
        cheats.stopPrank();
    }

    function testSellerCollectPayoutWhenOpen() public {
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
        cheats.startPrank(buyer1Address);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Open));
        cheats.expectRevert("Not Expired");
        silicaEthStaking.sellerCollectPayoutExpired();
        cheats.stopPrank();
    }

    function testSellerCollectPayoutExpiredWhenRunning() public {
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
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Running));
        cheats.startPrank(buyer1Address);
        cheats.expectRevert("Not Expired");
        silicaEthStaking.sellerCollectPayoutExpired();
        cheats.stopPrank();
    }

    function testSellerCollectPayoutExpiredWhenDefaulted() public {
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
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        rewardDue = silicaEthStaking.getRewardDueNextOracleUpdate();
        assertEq(rewardDue, (defaultStakingBaseReward * buyer1MintedAmount) / (10**(MasterSilicaEthStaking.decimals())));

        paymentToken.getFaucet(totalUpfrontPayment);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        cheats.stopPrank();

        address fakeSeller = address(42);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));
        cheats.startPrank(fakeSeller);
        cheats.expectRevert("Not Expired");
        silicaEthStaking.sellerCollectPayoutExpired();
        cheats.stopPrank();
    }

    function testSellerCollectPayoutExpiredWhenFinised() public {
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
        cheats.startPrank(sellerAddress);
        cheats.expectRevert("Not Expired");
        silicaEthStaking.sellerCollectPayoutExpired();
        cheats.stopPrank();
    }
}
