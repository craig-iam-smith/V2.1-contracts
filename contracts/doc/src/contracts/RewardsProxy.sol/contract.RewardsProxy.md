# RewardsProxy
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/RewardsProxy.sol)

**Inherits:**
[IRewardsProxy](/doc/src/contracts/interfaces/rewardsProxy/IRewardsProxy.sol/interface.IRewardsProxy.md)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

Contract that sends rewards to Silica contracts


## State Variables
### oracleRegistry

```solidity
IOracleRegistry immutable oracleRegistry;
```


## Functions
### constructor


```solidity
constructor(address _oracleRegistry);
```

### streamRewards

Function to stream rewards to Silica contracts


```solidity
function streamRewards(StreamRequest[] calldata streamRequests) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`streamRequests`|`StreamRequest[]`|Array of the StreamRequest struct ({ silicaAddress: rToken: amount: })|


### _streamReward

Internal function to safely stream rewards to Silica contracts


```solidity
function _streamReward(StreamRequest calldata streamRequest) internal;
```

