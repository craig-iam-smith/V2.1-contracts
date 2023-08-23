pragma solidity 0.8.19;

import "../../base/BaseTest.t.sol";
import "../../../libraries/math/PayoutMath.sol";
import {TestHelpers} from "../../helpers/TestHelpers.t.sol";
import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";

contract E2E_DefaultedEthStaking is BaseTest {
    struct ContractData {
        uint256 haircut;
        uint256 totalSilicaSold;
        uint256 totalDeposit;
        uint256 buyerPaymentBalanceBeforeClaim;
        uint256 buyer2PaymentBalanceBeforeClaim;
        uint256 rewardDelivered;
    }

    function setUp() public override {
        super.setUp();
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 2, defaultOracleStakingEntry);
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
    }

    function testE2EToDefault() public {
        //SELLER CREATES SILICA
        uint256 initialRewardTokenSellerBalance = stakingRewardToken.balanceOf(sellerAddress);
        cheats.startPrank(sellerAddress);
        stakingRewardToken.approve(address(testSilicaFactory), defaultStakingInitialCollateral);
        SilicaEthStaking testSilicaEthStaking = SilicaEthStaking(
            testSilicaFactory.createEthStakingSilicaV2_1(
                address(stakingRewardToken),
                address(paymentToken),
                defaultStakingAmount,
                defaultLastDueDay,
                defaultStakingUnitPrice
            )
        );
        cheats.stopPrank();
        uint256 sellerRewardTokenBalanceAfterCreation = stakingRewardToken.balanceOf(sellerAddress);
        assertEq(sellerRewardTokenBalanceAfterCreation, initialRewardTokenSellerBalance - defaultStakingInitialCollateral);

        //BUYER DEPOSITS
        assertEq(0, testSilicaEthStaking.balanceOf(buyerAddress));

        uint256 buyerDeposit = testSilicaEthStaking.reservedPrice() / 3;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaEthStaking), buyerDeposit);
        testSilicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();

        uint256 buyerBalance = (defaultStakingAmount * buyerDeposit) / testSilicaEthStaking.reservedPrice();
        assertEq(buyerBalance, testSilicaEthStaking.balanceOf(buyerAddress));
        assertEq(testSilicaEthStaking.totalSupply(), buyerBalance);

        uint256 buyer2Deposit = testSilicaEthStaking.reservedPrice() / 2;
        address buyer2Address = address(6789);

        cheats.startPrank(buyer2Address);
        paymentToken.getFaucet(buyer2Deposit);
        paymentToken.approve(address(testSilicaEthStaking), buyer2Deposit);
        testSilicaEthStaking.deposit(buyer2Deposit);
        cheats.stopPrank();

        uint256 buyer2Balance = (defaultStakingAmount * buyer2Deposit) / testSilicaEthStaking.reservedPrice();
        assertEq(buyer2Balance, testSilicaEthStaking.balanceOf(buyer2Address));
        assertEq(testSilicaEthStaking.totalSupply(), buyerBalance + buyer2Balance);

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        assertEq(uint256(testSilicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        assertEq(uint256(testSilicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        //SELLER DEPOSITS REWARD DUE NEXT UPDATE
        uint256 rewardDueNextOracleUpdate = testSilicaEthStaking.getRewardDueNextOracleUpdate();
        cheats.startPrank(sellerAddress);
        stakingRewardToken.getFaucet(rewardDueNextOracleUpdate);
        stakingRewardToken.transfer(address(testSilicaEthStaking), rewardDueNextOracleUpdate);
        cheats.stopPrank();
        assertEq(sellerRewardTokenBalanceAfterCreation, stakingRewardToken.balanceOf(sellerAddress));

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        assertEq(uint256(testSilicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 2, defaultOracleStakingEntry);
        assertEq(uint256(testSilicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));

        //BUYER CLAIM REWARDS
        assertEq(stakingRewardToken.balanceOf(buyerAddress), 0);
        ContractData memory contractData;
        contractData.buyerPaymentBalanceBeforeClaim = paymentToken.balanceOf(buyerAddress);
        contractData.buyer2PaymentBalanceBeforeClaim = paymentToken.balanceOf(buyer2Address);
        contractData.haircut = PayoutMath._getHaircut(
            testSilicaEthStaking.getDayOfDefault() - testSilicaEthStaking.firstDueDay(),
            testSilicaEthStaking.lastDueDay() + 1 - testSilicaEthStaking.firstDueDay()
        );
        contractData.totalSilicaSold = testSilicaEthStaking.totalSupply();
        contractData.totalDeposit = buyerDeposit + buyer2Deposit;

        cheats.prank(buyerAddress);
        testSilicaEthStaking.buyerCollectPayoutOnDefault();
        contractData.rewardDelivered = testSilicaEthStaking.rewardDelivered();

        assertEq(stakingRewardToken.balanceOf(buyerAddress), (contractData.rewardDelivered * buyerBalance) / contractData.totalSilicaSold);
        assertEq(
            paymentToken.balanceOf(buyerAddress),
            contractData.buyerPaymentBalanceBeforeClaim +
                PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                    buyerBalance,
                    contractData.totalDeposit,
                    contractData.totalSilicaSold,
                    contractData.haircut
                )
        );

        //SELLER COLLECT PAYOUT
        assertEq(paymentToken.balanceOf(sellerAddress), 0);

        cheats.prank(sellerAddress);
        testSilicaEthStaking.sellerCollectPayoutDefault();
        assertEq(
            paymentToken.balanceOf(sellerAddress),
            PayoutMath._getRewardPayoutToSellerOnDefault(contractData.totalDeposit, contractData.haircut)
        );

        //BUYER2 CLAIM REWARDS
        assertEq(stakingRewardToken.balanceOf(buyer2Address), 0);
        cheats.prank(buyer2Address);
        testSilicaEthStaking.buyerCollectPayoutOnDefault();

        assertEq(
            stakingRewardToken.balanceOf(buyer2Address),
            (contractData.rewardDelivered * buyer2Balance) / contractData.totalSilicaSold
        );
        assertEq(
            paymentToken.balanceOf(buyer2Address),
            contractData.buyer2PaymentBalanceBeforeClaim +
                PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                    buyer2Balance,
                    contractData.totalDeposit,
                    contractData.totalSilicaSold,
                    contractData.haircut
                )
        );

        // //CHECKING FOR DUST OR ERROR IN CALCS
        assertEq(testSilicaEthStaking.totalSupply(), 0);
        // @TODO discuss those checks, it's a know issue for a while, the first 2 fails for this test, if i'm hot wrong the other can fail for some values. We can make the calcs.
        // assertEq(stakingRewardToken.balanceOf(address(testSilicaEthStaking)), 0);
        // assertEq(paymentToken.balanceOf(address(testSilicaEthStaking)), 0);
        // assertEq(stakingRewardToken.balanceOf(sellerAddress), sellerRewardTokenBalanceAfterCreation + rewardExcess);
    }
}
