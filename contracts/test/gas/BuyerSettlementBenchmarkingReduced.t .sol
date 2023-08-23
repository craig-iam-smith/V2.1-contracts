pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";
import {BaseBenchmarking} from "./BaseBenchmarking.t.sol";

/**
    Benchmark buyerCollectPayout after initial settlement
    Gas costs should not change with contract duration
    NOTE: Keep in separate file from tests for seller, since that'll mess up the gas report
 */
contract BuyerSettlementBenchMarkingReduced is BaseBenchmarking {
    uint256 hashrate = 1000000000000000; //1 PH/s
    uint256 unitPrice = 81; //81 USDT / PH ==> 0.000081 USDT / GH

    function test10DayBuyerSettlementNoStateChange() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 10;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();
    }

    function test60DayBuyerSettlementNoStateChange() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 60;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();
    }

    function test100DayBuyerSettlementNoStateChange() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 100;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();
    }
}
