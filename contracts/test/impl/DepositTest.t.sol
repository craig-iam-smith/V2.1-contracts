pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

contract Deposit is BaseTest {
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

    function testOneDeposit() public {
        assertEq(testSilicaV2_1.balanceOf(buyerAddress), 0);
        assertEq(testSilicaV2_1.totalSupply(), 0);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), 0);
        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalance);

        uint256 buyerDepositAmount = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        testSilicaV2_1.deposit(buyerDepositAmount);
        cheats.stopPrank();

        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalance - buyerDepositAmount);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), buyerDepositAmount);
        assertEq(
            testSilicaV2_1.balanceOf(buyerAddress),
            TestHelpers.getSharesMintedWhenDeposit(address(testSilicaV2_1), buyerDepositAmount)
        );
        assertEq(testSilicaV2_1.totalSupply(), TestHelpers.getSharesMintedWhenDeposit(address(testSilicaV2_1), buyerDepositAmount));
    }

    function testManyDeposits() public {
        uint256 reservedPrice = testSilicaV2_1.reservedPrice();

        //BUYER0 DEPOSIT
        assertEq(testSilicaV2_1.balanceOf(buyerAddress), 0);
        assertEq(testSilicaV2_1.totalSupply(), 0);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), 0);
        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalance);
        uint256 buyer0DepositAmount = reservedPrice / 6;

        cheats.startPrank(buyerAddress);
        paymentToken.approve(address(testSilicaV2_1), buyer0DepositAmount);
        testSilicaV2_1.deposit(buyer0DepositAmount);
        cheats.stopPrank();

        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalance - buyer0DepositAmount);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), buyer0DepositAmount);
        assertEq(
            testSilicaV2_1.balanceOf(buyerAddress),
            TestHelpers.getSharesMintedWhenDeposit(address(testSilicaV2_1), buyer0DepositAmount)
        );
        assertEq(testSilicaV2_1.totalSupply(), TestHelpers.getSharesMintedWhenDeposit(address(testSilicaV2_1), buyer0DepositAmount));

        //BUYER1 DEPOSIT
        assertEq(testSilicaV2_1.balanceOf(buyer1Address), 0);
        assertEq(paymentToken.balanceOf(buyer1Address), 0);

        uint256 buyer1DepositAmount = reservedPrice / 2;

        cheats.startPrank(buyer1Address);
        paymentToken.getFaucet(buyer1DepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyer1DepositAmount);
        testSilicaV2_1.deposit(buyer1DepositAmount);
        cheats.stopPrank();

        assertEq(paymentToken.balanceOf(buyer1Address), 0);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), buyer0DepositAmount + buyer1DepositAmount);
        assertEq(
            testSilicaV2_1.balanceOf(buyer1Address),
            TestHelpers.getSharesMintedWhenDeposit(address(testSilicaV2_1), buyer1DepositAmount)
        );
        assertEq(
            testSilicaV2_1.totalSupply(),
            TestHelpers.getSharesMintedWhenDeposit(address(testSilicaV2_1), buyer0DepositAmount + buyer1DepositAmount)
        );

        //BUYER2 DEPOSIT
        assertEq(testSilicaV2_1.balanceOf(buyer2Address), 0);
        assertEq(paymentToken.balanceOf(buyer2Address), 0);

        uint256 buyer2DepositAmount = 100000;

        cheats.startPrank(buyer2Address);
        paymentToken.getFaucet(buyer2DepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyer2DepositAmount);
        testSilicaV2_1.deposit(buyer2DepositAmount);
        cheats.stopPrank();

        assertEq(paymentToken.balanceOf(buyer2Address), 0);
        assertEq(paymentToken.balanceOf(address(testSilicaV2_1)), buyer0DepositAmount + buyer1DepositAmount + buyer2DepositAmount);
        assertEq(
            testSilicaV2_1.balanceOf(buyer2Address),
            TestHelpers.getSharesMintedWhenDeposit(address(testSilicaV2_1), buyer2DepositAmount)
        );
        assertEq(
            testSilicaV2_1.totalSupply(),
            TestHelpers.getSharesMintedWhenDeposit(address(testSilicaV2_1), buyer0DepositAmount + buyer1DepositAmount + buyer2DepositAmount)
        );
    }

    function testDepositTooMuchInOneGo() public {
        uint256 reservedPrice = testSilicaV2_1.reservedPrice();

        uint256 buyerDepositAmount = reservedPrice + 1;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        cheats.expectRevert("Insufficient Supply");
        testSilicaV2_1.deposit(buyerDepositAmount);
        cheats.stopPrank();
    }

    function testDepositToMuchInManyGoes() public {
        uint256 reservedPrice = testSilicaV2_1.reservedPrice();

        uint256 buyer0DepositAmount = reservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyer0DepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyer0DepositAmount);
        testSilicaV2_1.deposit(buyer0DepositAmount);
        cheats.stopPrank();

        uint256 buyer1DepositAmount = reservedPrice / 2;

        cheats.startPrank(buyer1Address);
        paymentToken.getFaucet(buyer1DepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyer1DepositAmount);
        testSilicaV2_1.deposit(buyer1DepositAmount);
        cheats.stopPrank();

        uint256 buyer2DepositAmount = 10;

        cheats.startPrank(buyer2Address);
        paymentToken.getFaucet(buyer2DepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyer2DepositAmount);
        cheats.expectRevert("Insufficient Supply");
        testSilicaV2_1.deposit(buyer2DepositAmount);
        cheats.stopPrank();
    }

    function testDepositZero() public {
        uint256 buyerDepositAmount = 0;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyerDepositAmount);
        cheats.expectRevert("Invalid Value");
        testSilicaV2_1.deposit(buyerDepositAmount);
        cheats.stopPrank();
    }

    function testDepositWhileRunning() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        //BUYER2 DEPOSIT
        uint256 buyer2DepositAmount = 42;

        cheats.startPrank(buyer2Address);
        paymentToken.getFaucet(buyer2DepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyer2DepositAmount);
        cheats.expectRevert("Not Open");
        testSilicaV2_1.deposit(buyer2DepositAmount);
        cheats.stopPrank();
    }

    function testDepositWhileExpired() public {
        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), 41);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Expired));

        uint256 buyer2DepositAmount = 42;

        cheats.startPrank(buyer2Address);
        paymentToken.getFaucet(buyer2DepositAmount);
        paymentToken.approve(address(testSilicaV2_1), buyer2DepositAmount);
        cheats.expectRevert("Not Open");
        testSilicaV2_1.deposit(buyer2DepositAmount);
        cheats.stopPrank();
    }

    function testDepositWhileDefaulted() public {
        // SIMULATE DEFAULT ON DAY 41
        testSilicaV2_1.setDefaultDay(41);
        updateOracle(address(rewardTokenOracle), 41);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));

        //BUYER DEPOSITS
        uint256 buyerDeposit = 42424242;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        cheats.expectRevert("Not Open");
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();
    }

    function testDepositWhileFinished() public {
        // SIMULATE FINISH ON DAY 41
        updateOracle(address(rewardTokenOracle), 41);
        testSilicaV2_1.setFinishDay(41);
        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Finished));

        //BUYER DEPOSITS
        uint256 buyerDeposit = 42424242;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        cheats.expectRevert("Not Open");
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();
    }
}
