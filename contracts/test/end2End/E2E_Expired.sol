pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

contract E2E_Expired is BaseTest {
    uint256 hashrate = 60000000000;
    uint32 lastDueDay = 44;
    uint256 unitPrice = 10000000;

    function setUp() public override {
        super.setUp();
    }

    function testE2EToExpiry() public {
        //SELLER CREATES SILICA
        cheats.startPrank(sellerAddress);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        SilicaV2_1 testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate, lastDueDay, unitPrice)
        );
        cheats.stopPrank();

        uint32 firstDueDay = testSilicaV2_1.firstDueDay();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), firstDueDay - 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Expired));

        //SELLER COLLECT EXPIRY PAYOUT
        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayoutExpired();

        assertEq(rewardToken.balanceOf(sellerAddress), sellerRewardBalance);

        //CHECKING FOR DUST OR ERROR IN CALCS
        assertEq(testSilicaV2_1.totalSupply(), 0);
        assertEq(rewardToken.balanceOf(address(testSilicaV2_1)), 0);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), 0);
    }
}
