pragma solidity 0.8.19;

import "../../base/BaseTest.t.sol";
import {TestHelpers} from "../../helpers/TestHelpers.t.sol";
import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";

contract E2E_ExpiredEthStaking is BaseTest {
    function setUp() public override {
        super.setUp();
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 2, defaultOracleStakingEntry);
    }

    function testE2EToExpiry() public {
        //SELLER CREATES SILICA
        uint256 initialSellerBalance = stakingRewardToken.balanceOf(sellerAddress);
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
        uint256 sellerBalanceAfterCreation = stakingRewardToken.balanceOf(sellerAddress);
        assertEq(sellerBalanceAfterCreation, initialSellerBalance - defaultStakingInitialCollateral);

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        assertEq(uint256(testSilicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Expired));
        assertEq(uint256(stakingRewardToken.balanceOf(address(testSilicaEthStaking))), defaultStakingInitialCollateral);

        //SELLER COLLECT EXPIRY PAYOUT
        cheats.prank(sellerAddress);
        testSilicaEthStaking.sellerCollectPayoutExpired();

        assertEq(stakingRewardToken.balanceOf(sellerAddress), initialSellerBalance);

        //CHECKING FOR DUST OR ERROR IN CALCS
        assertEq(testSilicaEthStaking.totalSupply(), 0);
        assertEq(stakingRewardToken.balanceOf(address(testSilicaEthStaking)), 0);
        assertEq(paymentToken.balanceOf(address(testSilicaEthStaking)), 0);
    }
}
