pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";
import {BaseBenchmarking} from "./BaseBenchmarking.t.sol";

contract SettlementBenchMarking is BaseBenchmarking {
    uint256 hashrate = 1000000000000000; //1 PH/s
    uint256 unitPrice = 81; //81 USDT / PH ==> 0.000081 USDT / GH

    function test1DayBuyerSettlement() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();
    }

    function test1DaySellerSettlement() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();
    }

    function test10DayBuyerSettlement() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 10;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();
    }

    function test10DaySellerSettlement() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 10;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();
    }

    function test30DayBuyerSettlement() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 30;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();
    }

    function test30DaySellerSettlement() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 30;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();
    }

    function test60DayBuyerSettlement() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 60;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();
    }

    function test60DaySellerSettlement() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 60;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();
    }

    function test100DayBuyerSettlement() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 100;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(buyerAddress);
        testSilicaV2_1.buyerCollectPayout();
    }

    function test100DaySellerSettlement() public {
        uint32 firstDueDay = lastIndexedDay + 2;
        uint32 lastDueDay = firstDueDay + 100;

        runXDayContractToFinish(hashrate, unitPrice, firstDueDay, lastDueDay);

        cheats.prank(sellerAddress);
        testSilicaV2_1.sellerCollectPayout();
    }
}
