pragma solidity 0.8.19;

import "../../base/BaseTest.t.sol";
import {TestHelpers} from "../../helpers/TestHelpers.t.sol";
import {SilicaV2_1Storage} from "../../storage/SilicaV2_1Storage.t.sol";
import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";

contract DepositEthStaking is BaseTest {
    using SilicaV2_1Storage for SilicaEthStaking;

    address buyer1Address = address(12345);
    address buyer2Address = address(6789);

    SilicaEthStaking silicaEthStaking = new SilicaEthStaking();

    function setUp() public override {
        super.setUp();
        //SELLER CREATES SILICA
        cheats.startPrank(sellerAddress);
        silicaEthStaking = new SilicaEthStaking();
        silicaEthStaking.setRewardToken(address(stakingRewardToken));
        silicaEthStaking.setPaymentToken(address(paymentToken));
        silicaEthStaking.setOracleRegistry(address(oracleRegistry));
        silicaEthStaking.setOwner(address(sellerAddress));
        silicaEthStaking.setFirstDueDay(uint32(defaultFirstDueDay));
        silicaEthStaking.setLastDueDay(uint32(defaultLastDueDay));
        silicaEthStaking.setResourceAmount(defaultStakingAmount);
        silicaEthStaking.setReservedPrice(defaultStakingReservedPrice);
        silicaEthStaking.setInitialCollateral(defaultStakingInitialCollateral);
        defaultOracleStakingEntry.baseRewardPerIncrementPerDay = uint256(185000000000000);
        defaultOracleStakingEntry.timestamp = uint256((defaultFirstDueDay - 2) * 24 * 60 * 60);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 2, defaultOracleStakingEntry);
        cheats.stopPrank();
    }

    function testOneDeposit() public {
        assertEq(silicaEthStaking.balanceOf(buyerAddress), 0);
        assertEq(silicaEthStaking.totalSupply(), 0);
        assertEq(paymentToken.balanceOf(address(silicaEthStaking)), 0);
        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalance);

        uint256 buyerDepositAmount = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.approve(address(silicaEthStaking), buyerDepositAmount);
        silicaEthStaking.deposit(buyerDepositAmount);
        cheats.stopPrank();

        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalance - buyerDepositAmount);
        assertEq(paymentToken.balanceOf(address(silicaEthStaking)), buyerDepositAmount);
        assertEq(
            silicaEthStaking.balanceOf(buyerAddress),
            TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyerDepositAmount)
        );
        assertEq(silicaEthStaking.totalSupply(), TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyerDepositAmount));
    }

    function testManyDeposits() public {
        uint256 reservedPrice = silicaEthStaking.reservedPrice();

        //BUYER0 DEPOSIT
        assertEq(silicaEthStaking.balanceOf(buyerAddress), 0);
        assertEq(silicaEthStaking.totalSupply(), 0);
        assertEq(paymentToken.balanceOf(address(silicaEthStaking)), 0);
        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalance);
        uint256 buyer0DepositAmount = reservedPrice / 6;

        cheats.startPrank(buyerAddress);
        paymentToken.approve(address(silicaEthStaking), buyer0DepositAmount);
        silicaEthStaking.deposit(buyer0DepositAmount);
        cheats.stopPrank();

        assertEq(paymentToken.balanceOf(buyerAddress), buyerPaymentBalance - buyer0DepositAmount);
        assertEq(paymentToken.balanceOf(address(silicaEthStaking)), buyer0DepositAmount);
        assertEq(
            silicaEthStaking.balanceOf(buyerAddress),
            TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer0DepositAmount)
        );
        assertEq(silicaEthStaking.totalSupply(), TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer0DepositAmount));

        //BUYER1 DEPOSIT
        assertEq(silicaEthStaking.balanceOf(buyer1Address), 0);
        assertEq(silicaEthStaking.totalSupply(), TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer0DepositAmount));
        assertEq(paymentToken.balanceOf(address(silicaEthStaking)), buyer0DepositAmount);
        assertEq(paymentToken.balanceOf(buyer1Address), 0);
        uint256 buyer1DepositAmount = reservedPrice / 2;

        cheats.startPrank(buyer1Address);
        paymentToken.getFaucet(buyer1DepositAmount);
        paymentToken.approve(address(silicaEthStaking), buyer1DepositAmount);
        silicaEthStaking.deposit(buyer1DepositAmount);
        cheats.stopPrank();

        assertEq(paymentToken.balanceOf(buyer1Address), 0);
        assertEq(paymentToken.balanceOf(address(silicaEthStaking)), buyer0DepositAmount + buyer1DepositAmount);
        assertEq(
            silicaEthStaking.balanceOf(buyer1Address),
            TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer1DepositAmount)
        );
        assertEq(
            silicaEthStaking.totalSupply(),
            TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer0DepositAmount + buyer1DepositAmount)
        );

        //BUYER2 DEPOSIT
        assertEq(silicaEthStaking.balanceOf(buyer2Address), 0);
        assertEq(
            silicaEthStaking.totalSupply(),
            TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer0DepositAmount) +
                TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer1DepositAmount)
        );
        assertEq(paymentToken.balanceOf(address(silicaEthStaking)), buyer0DepositAmount + buyer1DepositAmount);
        assertEq(paymentToken.balanceOf(buyer1Address), 0);

        uint256 buyer2DepositAmount = 100000;

        cheats.startPrank(buyer2Address);
        paymentToken.getFaucet(buyer2DepositAmount);
        paymentToken.approve(address(silicaEthStaking), buyer2DepositAmount);
        silicaEthStaking.deposit(buyer2DepositAmount);
        cheats.stopPrank();

        assertEq(paymentToken.balanceOf(buyer1Address), 0);
        assertEq(paymentToken.balanceOf(address(silicaEthStaking)), buyer0DepositAmount + buyer1DepositAmount + buyer2DepositAmount);
        assertEq(
            silicaEthStaking.balanceOf(buyer2Address),
            TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer2DepositAmount)
        );
        assertEq(
            silicaEthStaking.totalSupply(),
            TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer0DepositAmount) +
                TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer1DepositAmount) +
                TestHelpers.getSharesMintedWhenDeposit(address(silicaEthStaking), buyer2DepositAmount)
        );
    }

    function testDepositToMuchInOneGo() public {
        uint256 reservedPrice = silicaEthStaking.reservedPrice();

        uint256 buyerDepositAmount = reservedPrice + 1;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDepositAmount);
        paymentToken.approve(address(silicaEthStaking), buyerDepositAmount);
        cheats.expectRevert("Insufficient Supply");
        silicaEthStaking.deposit(buyerDepositAmount);
        cheats.stopPrank();
    }

    function testDepositToMuchInManyGoes() public {
        uint256 reservedPrice = silicaEthStaking.reservedPrice();

        uint256 buyer0DepositAmount = reservedPrice / 2;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyer0DepositAmount);
        paymentToken.approve(address(silicaEthStaking), buyer0DepositAmount);
        silicaEthStaking.deposit(buyer0DepositAmount);
        cheats.stopPrank();

        uint256 buyer1DepositAmount = reservedPrice / 2;

        cheats.startPrank(buyer1Address);
        paymentToken.getFaucet(buyer1DepositAmount);
        paymentToken.approve(address(silicaEthStaking), buyer1DepositAmount);
        silicaEthStaking.deposit(buyer1DepositAmount);
        cheats.stopPrank();

        uint256 buyer2DepositAmount = 10;

        cheats.startPrank(buyer2Address);
        paymentToken.getFaucet(buyer2DepositAmount);
        paymentToken.approve(address(silicaEthStaking), buyer2DepositAmount);
        cheats.expectRevert("Insufficient Supply");
        silicaEthStaking.deposit(buyer2DepositAmount);
        cheats.stopPrank();
    }

    function testDepositZero() public {
        uint256 buyerDepositAmount = 0;

        cheats.startPrank(buyerAddress);
        paymentToken.approve(address(silicaEthStaking), buyerDepositAmount);
        cheats.expectRevert("Invalid Value");
        silicaEthStaking.deposit(buyerDepositAmount);
        cheats.stopPrank();
    }

    function testDepositWhileRunning() public {
        //BUYER DEPOSITS
        uint256 buyerDeposit = 4242424;

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();

        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Running));

        //BUYER2 DEPOSIT
        uint256 buyer2DepositAmount = 42;

        cheats.startPrank(buyer2Address);
        paymentToken.getFaucet(buyer2DepositAmount);
        paymentToken.approve(address(silicaEthStaking), buyer2DepositAmount);
        cheats.expectRevert("Not Open");
        silicaEthStaking.deposit(buyer2DepositAmount);
        cheats.stopPrank();
    }

    function testDepositWhileExpired() public {
        //ADVANCE TO NEXT DAY
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Expired));

        uint256 buyer2DepositAmount = 42;

        cheats.startPrank(buyer2Address);
        paymentToken.approve(address(silicaEthStaking), buyer2DepositAmount);
        cheats.expectRevert("Not Open");
        silicaEthStaking.deposit(buyer2DepositAmount);
        cheats.stopPrank();
    }

    function testDepositWhileDefaulted() public {
        // SIMULATE DEFAULT ON DAY 41
        silicaEthStaking.setDefaultDay(41);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay - 1, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay, defaultOracleStakingEntry);
        updateOracleEthStaking(address(oracleEthStaking), defaultFirstDueDay + 1, defaultOracleStakingEntry);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Defaulted));

        //BUYER DEPOSITS
        uint256 buyerDeposit = 42424242;

        cheats.startPrank(buyerAddress);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        cheats.expectRevert("Not Open");
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();
    }

    function testDepositWhileFinished() public {
        // SIMULATE FINISH ON DAY 44
        for (uint32 day = defaultFirstDueDay - 1; day <= defaultLastDueDay; day++) {
            updateOracleEthStaking(address(oracleEthStaking), day, defaultOracleStakingEntry);
        }
        silicaEthStaking.setFinishDay(defaultLastDueDay);
        assertEq(uint256(silicaEthStaking.getStatus()), uint256(SilicaV2_1Types.Status.Finished));

        //BUYER DEPOSITS
        uint256 buyerDeposit = 42424242;

        cheats.startPrank(buyerAddress);
        paymentToken.approve(address(silicaEthStaking), buyerDeposit);
        cheats.expectRevert("Not Open");
        silicaEthStaking.deposit(buyerDeposit);
        cheats.stopPrank();
    }
}
