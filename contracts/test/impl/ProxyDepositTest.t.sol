pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

contract ProxyDeposit is BaseTest {
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
        cheats.startPrank(sellerAddress);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate, lastDueDay, unitPrice)
        );
        cheats.stopPrank();
    }

    function testProxyDeposit() public {
        assertEq(testSilicaV2_1.balanceOf(buyerAddress), 0);
        assertEq(testSilicaV2_1.balanceOf(buyer1Address), 0);
        assertEq(testSilicaV2_1.totalSupply(), 0);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), 0);
        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalance);

        uint256 buyerDepositAmount = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        testSilicaV2_1.proxyDeposit(buyer1Address, buyerDepositAmount);
        cheats.stopPrank();

        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalance - buyerDepositAmount);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), buyerDepositAmount);
        assertEq(testSilicaV2_1.balanceOf(buyerAddress), 0);
        assertEq(
            testSilicaV2_1.balanceOf(buyer1Address),
            TestHelpers.getSharesMintedWhenDeposit(address(testSilicaV2_1), buyerDepositAmount)
        );
        assertEq(testSilicaV2_1.totalSupply(), TestHelpers.getSharesMintedWhenDeposit(address(testSilicaV2_1), buyerDepositAmount));
    }

    function testWrongAddress() public {
        uint256 buyerDepositAmount = 424242424242;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        cheats.expectRevert("Invalid Address");
        testSilicaV2_1.proxyDeposit(address(0), buyerDepositAmount);
        cheats.stopPrank();
    }

    function testWrongAmount() public {
        uint256 buyerDepositAmount = 0;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        cheats.expectRevert("Invalid Value");
        testSilicaV2_1.proxyDeposit(address(buyer1Address), buyerDepositAmount);
        cheats.stopPrank();
    }
}
