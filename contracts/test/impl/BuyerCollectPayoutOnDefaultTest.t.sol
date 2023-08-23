pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

import "../../libraries/math/PayoutMath.sol";

contract BuyerCollectPayoutOnDefault is BaseTest {
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

    function testBuyerCollectPayoutDefault() public {
        uint256 rewardDelivered = 100000000; // 1 WBTC
        uint256 buyer1Balance = 40000000000000; // 2/3 of ressource amount
        uint256 buyer2Balance = 20000000000000; // 1/3 of ressource amount
        uint256 initialCollateral = rewardToken.balanceOf(address(testSilicaV2_1));
        uint32 defaultDay = 44;
        uint256 totalUpfrontPayment = testSilicaV2_1.reservedPrice();

        testSilicaV2_1.setDefaultDay(1);
        testSilicaV2_1.setRewardDelivered(rewardDelivered);
        testSilicaV2_1.setBalance(buyer1Address, buyer1Balance);
        testSilicaV2_1.setBalance(buyer2Address, buyer2Balance);
        testSilicaV2_1.setTotalSupply(hashrate);
        testSilicaV2_1.setDefaultDay(defaultDay);
        testSilicaV2_1.setTotalUpfrontPayment(totalUpfrontPayment);

        cheats.startPrank(address(testSilicaV2_1));
        rewardToken.getFaucet(rewardDelivered - initialCollateral);
        paymentToken.getFaucet(totalUpfrontPayment);
        cheats.stopPrank();

        cheats.prank(buyer1Address);
        testSilicaV2_1.buyerCollectPayoutOnDefault();

        assertEq(rewardToken.balanceOf(buyer1Address), PayoutMath._getBuyerRewardPayout(rewardDelivered, buyer1Balance, hashrate));
        assertEq(
            rewardToken.balanceOf(address(testSilicaV2_1)),
            rewardDelivered - PayoutMath._getBuyerRewardPayout(rewardDelivered, buyer1Balance, hashrate)
        );
        assertEq(
            paymentToken.balanceOf(buyer1Address),
            PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                buyer1Balance,
                totalUpfrontPayment,
                hashrate,
                PayoutMath._getHaircut(
                    defaultDay - testSilicaV2_1.firstDueDay(),
                    testSilicaV2_1.lastDueDay() + 1 - testSilicaV2_1.firstDueDay()
                )
            )
        );
        assertEq(
            paymentToken.balanceOf(address(testSilicaV2_1)),
            totalUpfrontPayment -
                PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                    buyer1Balance,
                    totalUpfrontPayment,
                    hashrate,
                    PayoutMath._getHaircut(
                        defaultDay - testSilicaV2_1.firstDueDay(),
                        testSilicaV2_1.lastDueDay() + 1 - testSilicaV2_1.firstDueDay()
                    )
                )
        );
        assertEq(testSilicaV2_1.balanceOf(buyer1Address), 0);
        assertEq(testSilicaV2_1.totalSupply(), buyer2Balance);

        cheats.prank(buyer2Address);
        testSilicaV2_1.buyerCollectPayoutOnDefault();

        assertEq(rewardToken.balanceOf(buyer2Address), PayoutMath._getBuyerRewardPayout(rewardDelivered, buyer2Balance, hashrate));
        assertEq(
            rewardToken.balanceOf(address(testSilicaV2_1)),
            rewardDelivered -
                PayoutMath._getBuyerRewardPayout(rewardDelivered, buyer1Balance, hashrate) -
                PayoutMath._getBuyerRewardPayout(rewardDelivered, buyer2Balance, hashrate)
        );
        assertEq(
            paymentToken.balanceOf(buyer2Address),
            PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                buyer2Balance,
                totalUpfrontPayment,
                hashrate,
                PayoutMath._getHaircut(
                    defaultDay - testSilicaV2_1.firstDueDay(),
                    testSilicaV2_1.lastDueDay() + 1 - testSilicaV2_1.firstDueDay()
                )
            )
        );
        assertEq(
            paymentToken.balanceOf(address(testSilicaV2_1)),
            totalUpfrontPayment -
                PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                    buyer1Balance,
                    totalUpfrontPayment,
                    hashrate,
                    PayoutMath._getHaircut(
                        defaultDay - testSilicaV2_1.firstDueDay(),
                        testSilicaV2_1.lastDueDay() + 1 - testSilicaV2_1.firstDueDay()
                    )
                ) -
                PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
                    buyer2Balance,
                    totalUpfrontPayment,
                    hashrate,
                    PayoutMath._getHaircut(
                        defaultDay - testSilicaV2_1.firstDueDay(),
                        testSilicaV2_1.lastDueDay() + 1 - testSilicaV2_1.firstDueDay()
                    )
                )
        );
        assertEq(testSilicaV2_1.balanceOf(buyer2Address), 0);
        assertEq(testSilicaV2_1.totalSupply(), 0);
    }

    function testNonBuyerCollectPayoutDefault() public {
        uint256 rewardDelivered = 100000000; // 1 WBTC
        uint256 buyer1Balance = 40000000000000; // 2/3 of ressource amount
        uint256 buyer2Balance = 20000000000000; // 1/3 of ressource amount
        uint256 initialCollateral = rewardToken.balanceOf(address(testSilicaV2_1));
        uint32 defaultDay = 44;
        uint256 totalUpfrontPayment = testSilicaV2_1.reservedPrice();

        testSilicaV2_1.setDefaultDay(1);
        testSilicaV2_1.setRewardDelivered(rewardDelivered);
        testSilicaV2_1.setBalance(buyer1Address, buyer1Balance);
        testSilicaV2_1.setBalance(buyer2Address, buyer2Balance);
        testSilicaV2_1.setTotalSupply(hashrate);
        testSilicaV2_1.setDefaultDay(defaultDay);
        testSilicaV2_1.setTotalUpfrontPayment(totalUpfrontPayment);

        cheats.startPrank(address(testSilicaV2_1));
        rewardToken.getFaucet(rewardDelivered - initialCollateral);
        paymentToken.getFaucet(totalUpfrontPayment);
        cheats.stopPrank();

        address fakeBuyer = address(42);
        cheats.prank(fakeBuyer);
        cheats.expectRevert("Not Buyer");
        testSilicaV2_1.buyerCollectPayoutOnDefault();
    }

    function testBuyerCollectPayoutOnDefaultTwice() public {
        uint256 rewardDelivered = 100000000; // 1 WBTC
        uint256 buyer1Balance = 40000000000000; // 2/3 of ressource amount
        uint256 buyer2Balance = 20000000000000; // 1/3 of ressource amount
        uint256 initialCollateral = rewardToken.balanceOf(address(testSilicaV2_1));
        uint32 defaultDay = 44;
        uint256 totalUpfrontPayment = testSilicaV2_1.reservedPrice();

        testSilicaV2_1.setDefaultDay(1);
        testSilicaV2_1.setRewardDelivered(rewardDelivered);
        testSilicaV2_1.setBalance(buyer1Address, buyer1Balance);
        testSilicaV2_1.setBalance(buyer2Address, buyer2Balance);
        testSilicaV2_1.setTotalSupply(hashrate);
        testSilicaV2_1.setDefaultDay(defaultDay);
        testSilicaV2_1.setTotalUpfrontPayment(totalUpfrontPayment);

        cheats.startPrank(address(testSilicaV2_1));
        rewardToken.getFaucet(rewardDelivered - initialCollateral);
        paymentToken.getFaucet(totalUpfrontPayment);
        cheats.stopPrank();

        cheats.startPrank(buyer1Address);
        testSilicaV2_1.buyerCollectPayoutOnDefault();

        cheats.expectRevert("Not Buyer");
        testSilicaV2_1.buyerCollectPayoutOnDefault();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutOnDefaultWhenOpen() public {
        uint256 buyerDepositAmount = 4242424;
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Open));

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        testSilicaV2_1.deposit(buyerDepositAmount);
        cheats.stopPrank();

        cheats.startPrank(buyer1Address);
        cheats.expectRevert("Not Defaulted");
        testSilicaV2_1.buyerCollectPayoutOnDefault();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutOnDefaultWhenExpired() public {
        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), testSilicaV2_1.firstDueDay() - 1);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Expired));

        cheats.prank(buyer1Address);
        cheats.expectRevert("Not Defaulted");
        testSilicaV2_1.buyerCollectPayoutOnDefault();
    }

    function testBuyerCollectPayoutOnDefaultWhenRunning() public {
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
        cheats.expectRevert("Not Defaulted");
        testSilicaV2_1.buyerCollectPayoutOnDefault();
        cheats.stopPrank();
    }

    function testBuyerCollectPayoutOnDefaultWhenFinished() public {
        testSilicaV2_1.setStatus(SilicaV2_1Types.Status.Finished);

        cheats.prank(buyer1Address);
        cheats.expectRevert("Not Defaulted");
        testSilicaV2_1.buyerCollectPayoutOnDefault();
    }
}
