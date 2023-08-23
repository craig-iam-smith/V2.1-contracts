// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@std/Test.sol";
import "../../../OracleEthStaking.sol";
import "../OracleEthStakingStorage.t.sol";

contract TestOracleETHSTakingStorage is Test {
  using OracleEthStakingStorage for OracleEthStaking;

  OracleEthStaking testOracle;
  OracleEthStaking.AlkimiyaEthStakingIndex index;

  function setUp() public {
    testOracle = new OracleEthStaking("WETH");
    index = OracleEthStaking.AlkimiyaEthStakingIndex({
      baseRewardPerIncrementPerDay: 2000,
      burnFee: 20,
      priorityFee: 100,
      burnFeeNormalized: 200,
      priorityFeeNormalized: 1000,
      timestamp: 1
    });
  }

  function testSetLastIndexedDayEthStaking() public {
    testOracle.setLastIndexedDay(42);
    assertEq(testOracle.lastIndexedDay(), 42);
  }

  function testFuzzSetLastIndexedDayEthStaking(uint32 _day) public {
    testOracle.setLastIndexedDay(_day);
    assertEq(testOracle.lastIndexedDay(), _day);
  }

  function testSetIndexAtDayEthSTaking() public {
    testOracle.setIndexAtDay(42, index);
   (uint256 day, uint256 rewPerIncr, 
    uint256 burn, uint256 priority, 
    uint256 burnNorm, uint256 priorityNorm,
    uint256 time) = testOracle.get(42);
    assertEq(day, 42);
    assertEq(rewPerIncr, index.baseRewardPerIncrementPerDay);
    assertEq(burn, index.burnFee);
    assertEq(priority, index.priorityFee);
    assertEq(burnNorm, index.burnFeeNormalized);
    assertEq(priorityNorm, index.priorityFeeNormalized);
    assertEq(time, index.timestamp);
  }

  function testFuzzSetIndexAtDayEthStaking(uint32 _day, OracleEthStaking.AlkimiyaEthStakingIndex memory _index) public {
    vm.assume(_index.timestamp >= 1);
    vm.assume(_day > 0);
    testOracle.setLastIndexedDay(_day - 1);
    testOracle.setIndexAtDay(_day, _index);
   (uint256 day, uint256 rewPerIncr, 
    uint256 burn, uint256 priority, 
    uint256 burnNorm, uint256 priorityNorm,
    uint256 time) = testOracle.get(_day);
    assertEq(day, _day);
    assertEq(rewPerIncr, _index.baseRewardPerIncrementPerDay);
    assertEq(burn, _index.burnFee);
    assertEq(priority, _index.priorityFee);
    assertEq(burnNorm, _index.burnFeeNormalized);
    assertEq(priorityNorm, _index.priorityFeeNormalized);
    assertEq(time, _index.timestamp);
  }

}