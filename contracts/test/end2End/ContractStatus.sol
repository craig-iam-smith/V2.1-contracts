pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";

// Testing Silica's status methods
contract ContractStatus is BaseTest {
    SilicaV2_1 testSilicaV2_1;
    uint256 hashrate = 60000000000;
    uint32 lastDueDay = 43;
    uint256 unitPrice = 10000000;
    uint32 firstDueDay;

    function setUp() public override {
        super.setUp();

        //SELLER CREATES SILICA
        cheats.startPrank(sellerAddress);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate, lastDueDay, unitPrice)
        );
        cheats.stopPrank();

        firstDueDay = uint32(testSilicaV2_1.firstDueDay());

        //BUYER DEPOSITS
        assertEq(0, testSilicaV2_1.balanceOf(buyerAddress));

        uint256 buyerDeposit = testSilicaV2_1.reservedPrice();

        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(buyerDeposit);
        paymentToken.approve(address(testSilicaV2_1), buyerDeposit);
        testSilicaV2_1.deposit(buyerDeposit);
        cheats.stopPrank();

        assertTrue(testSilicaV2_1.isOpen());
        assertTrue(!testSilicaV2_1.isExpired());
        assertTrue(!testSilicaV2_1.isDefaulted());
        assertTrue(!testSilicaV2_1.isRunning());
        assertTrue(!testSilicaV2_1.isFinished());
    }

    function testStatusChangeToDefault() public {
        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), firstDueDay - 1);
        assertTrue(testSilicaV2_1.isRunning());
        assertTrue(!testSilicaV2_1.isOpen());
        assertTrue(!testSilicaV2_1.isExpired());
        assertTrue(!testSilicaV2_1.isDefaulted());
        assertTrue(!testSilicaV2_1.isFinished());

        for (uint32 day = firstDueDay; day < lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertTrue(testSilicaV2_1.isRunning());
            assertTrue(!testSilicaV2_1.isOpen());
            assertTrue(!testSilicaV2_1.isExpired());
            assertTrue(!testSilicaV2_1.isDefaulted());
            assertTrue(!testSilicaV2_1.isFinished());

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay);
        assertTrue(testSilicaV2_1.isRunning());
        assertTrue(!testSilicaV2_1.isOpen());
        assertTrue(!testSilicaV2_1.isExpired());
        assertTrue(!testSilicaV2_1.isDefaulted());
        assertTrue(!testSilicaV2_1.isFinished());

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay + 1);
        assertTrue(testSilicaV2_1.isDefaulted());
        assertTrue(!testSilicaV2_1.isOpen());
        assertTrue(!testSilicaV2_1.isExpired());
        assertTrue(!testSilicaV2_1.isRunning());
        assertTrue(!testSilicaV2_1.isFinished());
    }

    function testStatusChangeToFinished() public {
        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), firstDueDay - 1);
        assertTrue(testSilicaV2_1.isRunning());
        assertTrue(!testSilicaV2_1.isOpen());
        assertTrue(!testSilicaV2_1.isExpired());
        assertTrue(!testSilicaV2_1.isDefaulted());
        assertTrue(!testSilicaV2_1.isFinished());

        for (uint32 day = firstDueDay; day <= lastDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertTrue(testSilicaV2_1.isRunning());
            assertTrue(!testSilicaV2_1.isOpen());
            assertTrue(!testSilicaV2_1.isExpired());
            assertTrue(!testSilicaV2_1.isDefaulted());
            assertTrue(!testSilicaV2_1.isFinished());

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay + 1);
        assertTrue(testSilicaV2_1.isFinished());
        assertTrue(!testSilicaV2_1.isOpen());
        assertTrue(!testSilicaV2_1.isExpired());
        assertTrue(!testSilicaV2_1.isDefaulted());
        assertTrue(!testSilicaV2_1.isRunning());
    }

    function testStatusDefaultOneDay() public {
        for (uint32 day = firstDueDay - 1; day <= firstDueDay; day++) {
            //ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), day);
            assertTrue(testSilicaV2_1.isRunning());
            assertTrue(!testSilicaV2_1.isOpen());
            assertTrue(!testSilicaV2_1.isExpired());
            assertTrue(!testSilicaV2_1.isDefaulted());
            assertTrue(!testSilicaV2_1.isFinished());
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), firstDueDay + 1);
        assertTrue(testSilicaV2_1.isDefaulted());
        assertTrue(!testSilicaV2_1.isRunning());
        assertTrue(!testSilicaV2_1.isOpen());
        assertTrue(!testSilicaV2_1.isExpired());
        assertTrue(!testSilicaV2_1.isFinished());

        //defaultDay
        assertEq(uint256(testSilicaV2_1.getDayOfDefault()), firstDueDay);
        assertEq(uint256(testSilicaV2_1.defaultDay()), 0);
    }
}
