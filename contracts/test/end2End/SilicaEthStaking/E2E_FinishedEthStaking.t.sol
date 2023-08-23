pragma solidity 0.8.19;

import "../../base/BaseTest.t.sol";
import "../../../libraries/math/PayoutMath.sol";
import {TestHelpers} from "../../helpers/TestHelpers.t.sol";
import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";

contract E2E_FinishedEthStaking is BaseTest {
    function setUp() public override {
        super.setUp();
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 2, defaultOracleStakingEntry);
    }

    function testE2EFinished() public {
        //SELLER CREATES SILICA
        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        SilicaV2_1 testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(
                address(rewardToken),
                address(paymentToken),
                defaultResourceAmount,
                defaultLastDueDay,
                defaultUnitPrice
            )
        );
        cheats.stopPrank();

        //InitialMath check
        uint256 expectedReservedPrice = TestHelpers.getReservedPrice(address(testSilicaV2_1), defaultUnitPrice);
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

        assertEq(testSilicaV2_1.balanceOf(buyerAddress), (defaultResourceAmount * buyerDeposit) / testSilicaV2_1.reservedPrice());
        assertEq(testSilicaV2_1.totalSupply(), testSilicaV2_1.balanceOf(buyerAddress));

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), defaultFirstDueDay + 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), defaultFirstDueDay + 2);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        //SELLER DEPOSITS REWARD DUE NEXT UPDATE
        uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
        cheats.prank(sellerAddress);
        rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), defaultFirstDueDay + 3);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));
        assertEq(
            rewardToken.balanceOf(address(testSilicaV2_1)),
            TestHelpers.getContractBalanceOnDay(address(testSilicaV2_1), address(rewardTokenOracle))
        );

        //SELLER DEPOSITS REWARD DUE NEXT UPDATE
        rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
        cheats.prank(sellerAddress);
        rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), defaultLastDueDay);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));
        assertEq(
            rewardToken.balanceOf(address(testSilicaV2_1)),
            TestHelpers.getContractBalanceOnDay(address(testSilicaV2_1), address(rewardTokenOracle))
        );

        //SELLER DEPOSITS REWARD DUE NEXT UPDATE
        rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
        cheats.prank(sellerAddress);
        rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), defaultLastDueDay + 1);
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
}
