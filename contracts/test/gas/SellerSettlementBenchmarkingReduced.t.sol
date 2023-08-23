pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";
import {BaseBenchmarking} from "./BaseBenchmarking.t.sol";

/**
    Benchmark sellerCollectPayout after initial settlement
    Gas costs should not change with contract duration
    NOTE: Keep in separate file from tests for buyer, since that'll mess up the gas report
 */
contract SellerSettlementBenchMarkingReduced is BaseBenchmarking {
    uint256 hashrate = 1000000000000000; //1 PH/s
    uint256 unitPrice = 81; //81 USDT / PH ==> 0.000081 USDT / GH

    function test10DaySellerSettlementNoStateChange() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 10;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();
    }

    function test60DaySellerSettlementNoStateChange() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 60;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();
    }

    function test100DaySellerSettlementNoStateChange() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 100;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();
    }
}
