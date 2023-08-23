# RewardMath
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/libraries/math/RewardMath.sol)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

Calculations for when buyer initiates default


## Functions
### _getMiningRewardDue

Function to calculate the mining reward due by the seller


```solidity
function _getMiningRewardDue(uint256 _hashrate, uint256 _networkReward, uint256 _networkHashrate)
    internal
    pure
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_hashrate`|`uint256`|Underlying hashrate amount|
|`_networkReward`|`uint256`|Snapshot of the total network reward (block subsidy + fees)|
|`_networkHashrate`|`uint256`|The hashrate of the network (The basic unit of measurement of hashpower. Measures the number of SHA256d computations performed per second)|


### _getEthStakingRewardDue

Function to calculate the reward due by the seller for Eth Staking Silica


```solidity
function _getEthStakingRewardDue(uint256 _stakedAmount, uint256 _baseRewardPerIncrementPerDay, uint8 decimals)
    internal
    pure
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_stakedAmount`|`uint256`|The amount that has been staked|
|`_baseRewardPerIncrementPerDay`|`uint256`|The amount paid to the blockspace producer from the protocol, through inflation.|
|`decimals`|`uint8`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: The amount of reward tokens due|


