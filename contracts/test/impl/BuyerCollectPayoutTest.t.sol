pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

import "../../libraries/math/PayoutMath.sol";

contract BuyerCollectPayout is BaseTest {
    using SilicaV2_1Storage for SilicaV2_1;

    address buyer1Address = address(12345);
    address buyer2Address = address(6789);

    SilicaV2_1 testSilicaV2_1;

    uint256 hashrate = 60000000000000; //60000 gh
    uint256 lastDueDay = 44;
    uint256 unitPrice = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT | reservedPrice = 14667422

    uint256 rewardDelivered = 100000000; // 1 WBTC
    uint256 excess = 100000;
    uint256 buyer1Balance = 40000000000000; // 2/3 of ressource amount
    uint256 buyer2Balance = 20000000000000; // 1/3 of ressource amount

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

    function testBuyersCollectPayoutOnFinishedContractWithExcess() public {
        uint256 initialCollateral = rewardToken.balanceOf(address(testSilicaV2_1));

        testSilicaV2_1.setFinishDay(1);
        testSilicaV2_1.setRewardDelivered(rewardDelivered);
        testSilicaV2_1.setBalance(buyer1Address, buyer1Balance);
        testSilicaV2_1.setBalance(buyer2Address, buyer2Balance);
        testSilicaV2_1.setTotalSupply(hashrate);

        cheats.prank(address(testSilicaV2_1));
        rewardToken.getFaucet(rewardDelivered - initialCollateral + excess);

        cheats.prank(buyer1Address);
        testSilicaV2_1.buyerCollectPayout();

        assertEq(rewardToken.balanceOf(buyer1Address), PayoutMath._getBuyerRewardPayout(rewardDelivered, buyer1Balance, hashrate));
        assertEq(
            rewardToken.balanceOf(address(testSilicaV2_1)),
            rewardDelivered + excess - PayoutMath._getBuyerRewardPayout(rewardDelivered, buyer1Balance, hashrate)
        );
        assertEq(testSilicaV2_1.balanceOf(buyer1Address), 0);
        assertEq(testSilicaV2_1.totalSupply(), buyer2Balance);

        cheats.prank(buyer2Address);
        testSilicaV2_1.buyerCollectPayout();

        assertEq(rewardToken.balanceOf(buyer2Address), PayoutMath._getBuyerRewardPayout(rewardDelivered, buyer2Balance, hashrate));
        assertEq(
            rewardToken.balanceOf(address(testSilicaV2_1)),
            rewardDelivered +
                excess -
                PayoutMath._getBuyerRewardPayout(rewardDelivered, buyer1Balance, hashrate) -
                PayoutMath._getBuyerRewardPayout(rewardDelivered, buyer2Balance, hashrate)
        );
        assertEq(testSilicaV2_1.balanceOf(buyer2Address), 0);
        assertEq(testSilicaV2_1.totalSupply(), 0);
    }

    function testNonBuyerTriesToCollectPayout() public {
        uint256 initialCollateral = rewardToken.balanceOf(address(testSilicaV2_1));

        testSilicaV2_1.setFinishDay(1);
        testSilicaV2_1.setRewardDelivered(rewardDelivered);
        testSilicaV2_1.setBalance(buyer1Address, buyer1Balance);
        testSilicaV2_1.setBalance(buyer2Address, buyer2Balance);
        testSilicaV2_1.setTotalSupply(hashrate);

        cheats.prank(address(testSilicaV2_1));
        rewardToken.getFaucet(rewardDelivered - initialCollateral + excess);

        address fakeBuyer = address(11111111111);
        cheats.prank(fakeBuyer);
        cheats.expectRevert("Not Buyer");
        testSilicaV2_1.buyerCollectPayout();
    }

    function testBuyerTriesToCollectTwice() public {
        uint256 initialCollateral = rewardToken.balanceOf(address(testSilicaV2_1));

        testSilicaV2_1.setFinishDay(1);
        testSilicaV2_1.setRewardDelivered(rewardDelivered);
        testSilicaV2_1.setBalance(buyer1Address, buyer1Balance);
        testSilicaV2_1.setBalance(buyer2Address, buyer2Balance);
        testSilicaV2_1.setTotalSupply(hashrate);

        cheats.prank(address(testSilicaV2_1));
        rewardToken.getFaucet(rewardDelivered - initialCollateral + excess);

        //FIRST COLLECTPAYOUT
        cheats.startPrank(buyer1Address);
        testSilicaV2_1.buyerCollectPayout();

        //SECOND COLLECTPAYOUT
        cheats.expectRevert("Not Buyer");
        testSilicaV2_1.buyerCollectPayout();
        cheats.stopPrank();
    }

    function testBuyerTriesCollectPayoutWhenOpen() public {
        uint256 buyerDepositAmount = 4242424;
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Open));

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        testSilicaV2_1.deposit(buyerDepositAmount);
        cheats.stopPrank();

        cheats.startPrank(buyer1Address);
        cheats.expectRevert("Not Finished");
        testSilicaV2_1.buyerCollectPayout();
        cheats.stopPrank();
    }

    function testBuyerTriesCollectPayoutWhenExpired() public {
        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), testSilicaV2_1.firstDueDay() - 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Expired));

        cheats.prank(buyer1Address);
        cheats.expectRevert("Not Finished");
        testSilicaV2_1.buyerCollectPayout();
    }

    function testBuyerTriesCollectPayoutWhenRunning() public {
        uint256 buyerDepositAmount = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        testSilicaV2_1.deposit(buyerDepositAmount);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), testSilicaV2_1.firstDueDay() - 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        cheats.startPrank(buyer1Address);
        cheats.expectRevert("Not Finished");
        testSilicaV2_1.buyerCollectPayout();
        cheats.stopPrank();
    }

    function testBuyerTriesCollectPayoutWhenDefault() public {
        testSilicaV2_1.setStatus(SilicaV2_1Types.Status.Defaulted);

        cheats.prank(buyer1Address);
        cheats.expectRevert("Not Finished");
        testSilicaV2_1.buyerCollectPayout();
    }
}
