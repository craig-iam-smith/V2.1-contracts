// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@std/Test.sol";
import "../../libraries/math/RewardMath.sol";

contract RewardMathTest is Test {

  function testGetMiningRewardDue() public {
    uint256 hashrate = 6000000;
    uint256 networkReward = 20000;
    uint256 networkHashrate = 2000000;
    uint256 expected = 60000;
    uint256 actual = RewardMath._getMiningRewardDue(
      hashrate,
      networkReward,
      networkHashrate
    );
    assertEq(expected, actual);
  }

  function testFuzzGetMiningRewardDue(
    uint256 _hashrate,
    uint256 _networkReward,
    uint256 _networkHashrate
  ) public {
    _hashrate = bound(_hashrate, 1, 1e18);
    _networkReward = bound(_networkReward, 1, 1e18);
    _networkHashrate = bound(_networkHashrate,1, 1e18);
    uint256 expected = (_hashrate * _networkReward) / _networkHashrate;
    uint256 actual = RewardMath._getMiningRewardDue(
      _hashrate,
      _networkReward,
      _networkHashrate
    );
    assertEq(expected, actual);
  }

  function testGetEthStakingRewardDue() public {
    uint256 stakedAmount = 10000;
    uint256 baseRewardPerIncrementPerDay = 1000;
    uint8 decimals = 6;
    uint256 expected = 10;
    uint256 actual = RewardMath._getEthStakingRewardDue(
      stakedAmount,
      baseRewardPerIncrementPerDay,
      decimals
    );
    assertEq(expected, actual);
  }

  function testFuzzGetEthStakingRewardDue(
    uint256 _stakedAmount,
    uint256 _baseRewardPerIncrementPerDay,
    uint8 _decimals
  ) public {
    _stakedAmount = bound(_stakedAmount, 1, 1e18);
    _baseRewardPerIncrementPerDay = bound(_baseRewardPerIncrementPerDay, 1, 1e18);
    _decimals = uint8(bound(_decimals, 1, 18));
    uint256 expected = (_stakedAmount * _baseRewardPerIncrementPerDay) / (10**_decimals);
    uint256 actual = RewardMath._getEthStakingRewardDue(
      _stakedAmount,
      _baseRewardPerIncrementPerDay,
      _decimals
    );
    assertEq(expected, actual);
  }
}