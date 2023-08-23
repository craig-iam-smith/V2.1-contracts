pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

import "../../libraries/math/PayoutMath.sol";

contract SellerCollectPayoutExpired is BaseTest {
    using SilicaV2_1Storage for SilicaV2_1;

    address buyer1Address = address(12345);
    address buyer2Address = address(6789);

    SilicaV2_1 testSilicaV2_1;

    uint256 hashrate = 60000000000000; //60000 gh
    uint256 lastDueDay = 44;
    uint256 unitPrice = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT | reservedPrice = 14667422

    function setUp() public override {
        super.setUp();
        //SELLER CREATES SILICA
        uint256 sellerRewardBalance = 10000000000000000000000000;

        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate, lastDueDay, unitPrice)
        );
        cheats.stopPrank();
    }

    function testSellerCollectPayoutExpired() public {
        uint256 initialCollateral = testSilicaV2_1.initialCollateral();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Expired));

        uint256 sellerRewardBalanceBeforePayout = rewardToken.balanceOf(sellerAddress);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayoutExpired();

        assertEq(rewardToken.balanceOf(sellerAddress), sellerRewardBalanceBeforePayout + initialCollateral);
        assertEq(rewardToken.balanceOf(address(testSilicaV2_1)), 0);
    }

    function testFakeSellerCollectPayoutExpired() public {
        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Expired));

        address fakeSeller = address(42);
        cheats.prank(fakeSeller);
        cheats.expectRevert("Not Owner");
        testSilicaV2_1.sellerCollectPayoutExpired();
    }

    function testSellerCollectPayoutWhenOpen() public {
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Open));

        cheats.prank(sellerAddress);
        cheats.expectRevert("Not Expired");
        testSilicaV2_1.sellerCollectPayoutExpired();
    }

    function testSellerCollectPayoutExpiredWhenRunning() public {
        uint256 buyerDepositAmount = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        testSilicaV2_1.deposit(buyerDepositAmount);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);

        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        cheats.prank(sellerAddress);
        cheats.expectRevert("Not Expired");
        testSilicaV2_1.sellerCollectPayoutExpired();
    }

    function testSellerCollectPayoutExpiredWhenDefaulted() public {
        testSilicaV2_1.setStatus(SilicaV2_1Types.Status.Defaulted);

        cheats.prank(sellerAddress);
        cheats.expectRevert("Not Expired");
        testSilicaV2_1.sellerCollectPayoutExpired();
    }

    function testSellerCollectPayoutExpiredWhenFinised() public {
        testSilicaV2_1.setStatus(SilicaV2_1Types.Status.Finished);

        cheats.prank(sellerAddress);
        cheats.expectRevert("Not Expired");
        testSilicaV2_1.sellerCollectPayoutExpired();
    }
}
