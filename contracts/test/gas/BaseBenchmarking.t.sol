pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

contract BaseBenchmarking is BaseTest {
    SilicaV2_1 testSilicaV2_1;

    function setUp() public override {
        super.setUp();
    }

    function createTestSilica(
        uint256 hashrate,
        uint256 lastDueDay,
        uint256 unitPrice
    ) internal returns (address contractAddress) {
        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
        rewardToken.approve(address(testSilicaFactory), 10000000000000000000000000);

        contractAddress = testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate, lastDueDay, unitPrice);
        cheats.stopPrank();
    }

    function depositHelper(uint256 amount) internal {
        cheats.startPrank(buyerAddress);
        paymentToken.getFaucet(amount);
        paymentToken.approve(address(testSilicaV2_1), amount);
        testSilicaV2_1.deposit(amount);
        cheats.stopPrank();
    }

    function runXDayContractToFinish(
        uint256 hashrate,
        uint256 unitPrice,
        uint32 firstDueDay,
        uint32 lastDueDay
    ) internal {
        testSilicaV2_1 = SilicaV2_1(createTestSilica(hashrate, lastDueDay, unitPrice));

        //BUYER DEPOSITS
        uint256 buyerDeposit = testSilicaV2_1.reservedPrice() / 2;
        depositHelper(buyerDeposit);

        // ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), firstDueDay - 1);

        // ADVANCE TO NEXT DAY
        for (uint256 day = firstDueDay; day <= lastDueDay; day++) {
            // ADVANCE TO NEXT DAY
            updateOracle(address(rewardTokenOracle), uint32(day));

            //SELLER DEPOSITS REWARD DUE NEXT UPDATE
            uint256 rewardDueNextOracleUpdate = testSilicaV2_1.getRewardDueNextOracleUpdate();
            cheats.prank(sellerAddress);
            rewardToken.transfer(address(testSilicaV2_1), rewardDueNextOracleUpdate);
        }

        //ADVANCE TO NEXT DAY
        updateOracle(address(rewardTokenOracle), lastDueDay + 1);
    }
}
