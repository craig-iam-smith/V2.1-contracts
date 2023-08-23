// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@std/Test.sol";
import "../../../Oracle.sol";
import "../OracleStorage.t.sol";

contract TestOracleStorage is Test {
  using OracleStorage for Oracle;

  Oracle testOracle;
  Oracle.AlkimiyaIndex index;

  function setUp() public {
    testOracle = new Oracle("WBTC");
    index = Oracle.AlkimiyaIndex({
      referenceBlock: 4242,
      timestamp: 1,
      hashrate: 6060,
      difficulty: 2000,
      reward: 1000,
      fees: 200
    });
  }

  function testSetLastIndexedDay() public {
    testOracle.setLastIndexedDay(42);
    assertEq(testOracle.lastIndexedDay(), 42);
  }

  function testFuzzSetLastIndexedDay(uint32 _day) public {
    testOracle.setLastIndexedDay(_day);
    assertEq(testOracle.lastIndexedDay(), _day);
  }

  function testSetIndexAtDay() public {
    testOracle.setIndexAtDay(42, index);
   (uint256 day, uint256 refBlock, 
    uint256 rate, uint256 rew, 
    uint256 fee, uint256 diff,
    uint256 time) = testOracle.get(42);
    assertEq(day, 42);
    assertEq(refBlock, index.referenceBlock);
    assertEq(rate, index.hashrate);
    assertEq(rew, index.reward);
    assertEq(fee, index.fees);
    assertEq(diff, index.difficulty);
    assertEq(time, index.timestamp);
  }

  function testFuzzSetIndexAtDay(uint32 _day, Oracle.AlkimiyaIndex memory _index) public {
    vm.assume(_index.timestamp == 1);
    vm.assume(_day >= 1);
    testOracle.setLastIndexedDay(_day - 1);
    testOracle.setIndexAtDay(_day, _index);
   (uint256 day, uint256 refBlock, 
    uint256 rate, uint256 rew, 
    uint256 fee, uint256 diff,
    uint256 time) = testOracle.get(_day);
    assertEq(day, _day);
    assertEq(refBlock, _index.referenceBlock);
    assertEq(rate, _index.hashrate);
    assertEq(rew, _index.reward);
    assertEq(fee, _index.fees);
    assertEq(diff, _index.difficulty);
    assertEq(time, _index.timestamp);
  }
}