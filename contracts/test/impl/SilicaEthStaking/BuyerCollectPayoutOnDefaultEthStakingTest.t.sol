pragma solidity 0.8.19;

import "../../base/BaseTest.t.sol";
import {TestHelpers} from "../../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";

import "../../../libraries/math/PayoutMath.sol";

contract BuyerCollectPayoutOnDefaultEthStaking is BaseTest {
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

    function testBuyerCollectPayoutDefault() public {
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

        cheats.startPrank(buyer1Address);
        uint8 status = uint8(silicaEthStaking.getStatus());
        assertEq(status, 3);
        silicaEthStaking.buyerCollectPayoutOnDefault();

        uint256 haircut = PayoutMath._getHaircut(0, defaultLastDueDay - defaultFirstDueDay + 1);

        assertEq(
            stakingRewardToken.balanceOf(buyer1Address),
            PayoutMath._getRewardTokenPayoutToBuyerOnDefault(
                defaultStakingInitialCollateral,
                buyer1MintedAmount,
                buyer1MintedAmount + buyer2MintedAmount
            )
        );
        assertEq(
            paymentToken.balanceOf(buyer1Address),
            PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                buyer1MintedAmount,
                totalUpfrontPayment,
                buyer1MintedAmount + buyer2MintedAmount,
                haircut
            )
        );
        assertEq(
            paymentToken.balanceOf(address(silicaEthStaking)),
            totalUpfrontPayment -
                PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                    buyer1MintedAmount,
                    totalUpfrontPayment,
                    buyer1MintedAmount + buyer2MintedAmount,
                    haircut
                )
        );
        assertEq(silicaEthStaking.balanceOf(buyer1Address), 0);
        assertEq(silicaEthStaking.totalSupply(), buyer2MintedAmount);
        cheats.stopPrank();

        cheats.prank(buyer2Address);
        silicaEthStaking.buyerCollectPayoutOnDefault();
        assertEq(
            stakingRewardToken.balanceOf(buyer2Address),
            PayoutMath._getRewardTokenPayoutToBuyerOnDefault(
                defaultStakingInitialCollateral,
                buyer2MintedAmount,
                buyer1MintedAmount + buyer2MintedAmount
            )
        );
        assertEq(
            stakingRewardToken.balanceOf(address(silicaEthStaking)),
            rewardDelivered -
                PayoutMath._getBuyerRewardPayout(
                    defaultStakingInitialCollateral,
                    buyer1MintedAmount,
                    buyer1MintedAmount + buyer2MintedAmount
                ) -
                PayoutMath._getBuyerRewardPayout(
                    defaultStakingInitialCollateral,
                    buyer2MintedAmount,
                    buyer1MintedAmount + buyer2MintedAmount
                )
        );
        assertEq(
            paymentToken.balanceOf(buyer2Address),
            PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                buyer2MintedAmount,
                totalUpfrontPayment,
                buyer1MintedAmount + buyer2MintedAmount,
                haircut
            )
        );
        assertEq(
            paymentToken.balanceOf(address(silicaEthStaking)),
            totalUpfrontPayment -
                PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                    buyer1MintedAmount,
                    totalUpfrontPayment,
                    buyer1MintedAmount + buyer2MintedAmount,
                    haircut
                ) -
                PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                    buyer2MintedAmount,
                    totalUpfrontPayment,
                    buyer1MintedAmount + buyer2MintedAmount,
                    haircut
                )
        );
        assertEq(silicaEthStaking.balanceOf(buyer2Address), 0);
        assertEq(silicaEthStaking.totalSupply(), 0);
    }

    function testNonBuyerCollectPayoutDefault() public {
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

        address fakeBuyer = address(42);
        cheats.startPrank(fakeBuyer);
        cheats.expectRevert("Not Buyer");
        silicaEthStaking.buyerCollectPayoutOnDefault();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutOnDefaultTwice() public {
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

        cheats.startPrank(buyer1Address);
        silicaEthStaking.buyerCollectPayoutOnDefault();

        cheats.expectRevert("Not Buyer");
        silicaEthStaking.buyerCollectPayoutOnDefault();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutOnDefaultWhenOpen() public {
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
        cheats.expectRevert("Not Defaulted");
        silicaEthStaking.buyerCollectPayoutOnDefault();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutOnDefaultWhenExpired() public {
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
        cheats.expectRevert("Not Defaulted");
        silicaEthStaking.buyerCollectPayoutOnDefault();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutOnDefaultWhenRunning() public {
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
        cheats.expectRevert("Not Defaulted");
        silicaEthStaking.buyerCollectPayoutOnDefault();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutOnDefaultWhenFinished() public {
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
        cheats.expectRevert("Not Defaulted");
        silicaEthStaking.buyerCollectPayoutOnDefault();
        cheats.stopPrank();
    }
}
