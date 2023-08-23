# IOracleEthStaking
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/interfaces/oracle/oracleEthStaking/IOracleEthStaking.sol)

**Inherits:**
[IOracleEthStakingEvents](/doc/src/contracts/interfaces/oracle/oracleEthStaking/IOracleEthStakingEvents.sol/interface.IOracleEthStakingEvents.md)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

This is the interface for Proof of Stake Oracle contract


## Functions
### updateIndex

Update the Alkimiya Index for PoS instruments on Oracle for a given day


```solidity
function updateIndex(
    uint256 _referenceDay,
    uint256 _baseRewardPerIncrementPerDay,
    uint256 _burnFee,
    uint256 _priorityFee,
    uint256 _burnFeeNormalized,
    uint256 _priorityFeeNormalized,
    bytes memory signature
) external returns (bool success);
```

### get

Function to return Oracle index on given day


```solidity
function get(uint256 _referenceDay)
    external
    view
    returns (
        uint256 referenceDay,
        uint256 baseRewardPerIncrementPerDay,
        uint256 burnFee,
        uint256 priorityFee,
        uint256 burnFeeNormalized,
        uint256 priorityFeeNormalized,
        uint256 timestamp
    );
```

### getInRange

Function to return array of oracle data between firstday and lastday (inclusive)


```solidity
function getInRange(uint256 _firstDay, uint256 _lastDay)
    external
    view
    returns (uint256[] memory baseRewardPerIncrementPerDayArray);
```

### isDayIndexed

Return if the network data on a given day is updated to Oracle


```solidity
function isDayIndexed(uint256 _referenceDay) external view returns (bool);
```

### getLastIndexedDay

Return the last day on which the Oracle is updated


```solidity
function getLastIndexedDay() external view returns (uint32);
```

