pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CreateEthStakingSilica is BaseTest {
    function setUp() public override {
        super.setUp();
        defaultOracleStakingEntry.baseRewardPerIncrementPerDay = uint256(185000000000000);
        defaultOracleStakingEntry.timestamp = uint256((defaultFirstDueDay + 1) * 24 * 60 * 60);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
    }

    function testCreateSilicaV2_1() public {
        //SELLER CREATES SILICA
        cheats.startPrank(sellerAddress);
        stakingRewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        uint256 sellerBalanceBefore = IERC20(address(stakingRewardToken)).balanceOf(address(sellerAddress));
        SilicaEthStaking testSilicaEthStaking = SilicaEthStaking(
            testSilicaFactory.createEthStakingSilicaV2_1(
                address(stakingRewardToken),
                address(paymentToken),
                defaultStakingAmount,
                defaultLastDueDay,
                defaultStakingUnitPrice
            )
        );

        uint256 collateralAmount = IERC20(address(stakingRewardToken)).balanceOf(address(testSilicaEthStaking));
        assertEq(collateralAmount, sellerBalanceBefore - IERC20(address(stakingRewardToken)).balanceOf(address(sellerAddress)));
        assertEq(collateralAmount, TestHelpers.getInitialCollateralEthStaking(address(testSilicaEthStaking), address(oracleEthStaking)));
        assertEq(address(stakingRewardToken), testSilicaEthStaking.getRewardToken());
        assertEq(address(paymentToken), testSilicaEthStaking.getPaymentToken());
        assertEq(testSilicaEthStaking.getCommodityType(), 2);
        cheats.stopPrank();
    }
}
