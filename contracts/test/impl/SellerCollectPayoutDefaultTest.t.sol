pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

import "../../libraries/math/PayoutMath.sol";

contract SellerCollectPayoutDefault is BaseTest {
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

    function testSellerCollectPayoutDefault() public {
        uint256 totalUpfrontPayment = 100000000000;
        uint256 rewardDelivered = 80000000;
        uint32 defaultDay = 43;
        uint256 rewardExcess = 420000;
        uint256 initialCollateral = testSilicaV2_1.initialCollateral();
        SilicaV2_1Types.Status status = SilicaV2_1Types.Status.Defaulted;

        testSilicaV2_1.setTotalUpfrontPayment(totalUpfrontPayment);
        testSilicaV2_1.setRewardDelivered(rewardDelivered);
        testSilicaV2_1.setDefaultDay(defaultDay);
        testSilicaV2_1.setRewardExcess(rewardExcess);
        testSilicaV2_1.setStatus(status);

        uint256 sellerRewardBalanceBeforePayout = rewardToken.balanceOf(sellerAddress);
        uint256 sellerPaymentBalanceBeforePayout = paymentToken.balanceOf(sellerAddress);

        cheats.startPrank(address(testSilicaV2_1));
        rewardToken.getFaucet(rewardDelivered - initialCollateral + rewardExcess);
        paymentToken.getFaucet(totalUpfrontPayment);
        cheats.stopPrank();

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayoutDefault();

        assertEq(rewardToken.balanceOf(sellerAddress), sellerRewardBalanceBeforePayout + rewardExcess);
        uint256 totalAmountOfDepositsRequired = testSilicaV2_1.lastDueDay() + 1 - testSilicaV2_1.firstDueDay();
        uint256 haircut = PayoutMath._getHaircut(defaultDay - testSilicaV2_1.firstDueDay(), totalAmountOfDepositsRequired);
        assertEq(
            paymentToken.balanceOf(sellerAddress),
            sellerPaymentBalanceBeforePayout + PayoutMath._getRewardPayoutToSellerOnDefault(totalUpfrontPayment, haircut)
        );
        assertEq(rewardToken.balanceOf(address(testSilicaV2_1)), rewardDelivered);
        assertEq(
            paymentToken.balanceOf(address(testSilicaV2_1)),
            totalUpfrontPayment - PayoutMath._getRewardPayoutToSellerOnDefault(totalUpfrontPayment, haircut)
        );
    }

    function testSellerCollectPayoutDefaultTwice() public {
        uint256 totalUpfrontPayment = 100000000000;
        uint256 rewardDelivered = 80000000;
        uint32 defaultDay = 43;
        uint256 rewardExcess = 420000;
        uint256 initialCollateral = testSilicaV2_1.initialCollateral();
        SilicaV2_1Types.Status status = SilicaV2_1Types.Status.Defaulted;

        testSilicaV2_1.setTotalUpfrontPayment(totalUpfrontPayment);
        testSilicaV2_1.setRewardDelivered(rewardDelivered);
        testSilicaV2_1.setDefaultDay(defaultDay);
        testSilicaV2_1.setRewardExcess(rewardExcess);
        testSilicaV2_1.setStatus(status);

        cheats.startPrank(address(testSilicaV2_1));
        rewardToken.getFaucet(rewardDelivered - initialCollateral + rewardExcess);
        paymentToken.getFaucet(totalUpfrontPayment);
        cheats.stopPrank();

        cheats.startPrank(sellerAddress);
        testSilicaV2_1.sellerCollectPayoutDefault();

        cheats.expectRevert("Payout already collected");
        testSilicaV2_1.sellerCollectPayoutDefault();
    }

    function testNotSellerCollectPayoutDefault() public {
        uint256 totalUpfrontPayment = 100000000000;
        uint256 rewardDelivered = 80000000;
        uint32 defaultDay = 43;
        uint256 rewardExcess = 420000;
        uint256 initialCollateral = testSilicaV2_1.initialCollateral();
        SilicaV2_1Types.Status status = SilicaV2_1Types.Status.Defaulted;

        testSilicaV2_1.setTotalUpfrontPayment(totalUpfrontPayment);
        testSilicaV2_1.setRewardDelivered(rewardDelivered);
        testSilicaV2_1.setDefaultDay(defaultDay);
        testSilicaV2_1.setRewardExcess(rewardExcess);
        testSilicaV2_1.setStatus(status);

        cheats.startPrank(address(testSilicaV2_1));
        rewardToken.getFaucet(rewardDelivered - initialCollateral + rewardExcess);
        paymentToken.getFaucet(totalUpfrontPayment);
        cheats.stopPrank();

        address fakeSeller = address(42);
        cheats.startPrank(fakeSeller);
        cheats.expectRevert("Not Owner");
        testSilicaV2_1.sellerCollectPayoutDefault();
    }

    function testSellerCollectPayoutDefaultWhenOpen() public {
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Open));

        cheats.startPrank(sellerAddress);
        cheats.expectRevert("Not Defaulted");
        testSilicaV2_1.sellerCollectPayoutDefault();
    }

    function testSellerCollectPayoutDefaultWhenExpired() public {
        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);

        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Expired));

        cheats.startPrank(sellerAddress);
        cheats.expectRevert("Not Defaulted");
        testSilicaV2_1.sellerCollectPayoutDefault();
    }

    function testSellerCollectPayoutDefaultWhenRunning() public {
        uint256 buyerDepositAmount = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        testSilicaV2_1.deposit(buyerDepositAmount);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);

        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        cheats.startPrank(sellerAddress);
        cheats.expectRevert("Not Defaulted");
        testSilicaV2_1.sellerCollectPayoutDefault();
    }

    function testSellerCollectPayoutDefaultWhenFinished() public {
        testSilicaV2_1.setFinishDay(1);

        cheats.startPrank(sellerAddress);
        cheats.expectRevert("Not Defaulted");
        testSilicaV2_1.sellerCollectPayoutDefault();
    }
}
