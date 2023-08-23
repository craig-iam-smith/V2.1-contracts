# IOraclePoS
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/interfaces/oracle/IOraclePoS.sol)

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
### isDayIndexed

Return the Network data on a given day is updated to Oracle


```solidity
function isDayIndexed(uint256 _referenceDay) external view returns (bool);
```

### getLastIndexedDay

Return the last day on which the Oracle is updated


```solidity
function getLastIndexedDay() external view returns (uint32);
```

### updateIndex

Update the Alkimiya Index for PoS instruments on Oracle for a given day


```solidity
function updateIndex(
    uint32 _referenceDay,
    uint256 _referenceBlock,
    uint256 _currentSupply,
    uint256 _supplyCap,
    uint256 _maxStakingDuration,
    uint256 _maxConsumptionRate,
    uint256 _minConsumptionRate,
    uint256 _mintingPeriod,
    uint256 _scale,
    bytes memory signature
) external returns (bool success);
```

### get


```solidity
function get(uint256 _referenceDay)
    external
    view
    returns (
        uint256 referenceDay,
        uint256 referenceBlock,
        uint256 currentSupply,
        uint256 supplyCap,
        uint256 maxStakingDuration,
        uint256 maxConsumptionRate,
        uint256 minConsumptionRate,
        uint256 mintingPeriod,
        uint256 scale,
        uint256 timestamp
    );
```

## Events
### OracleUpdate

```solidity
event OracleUpdate(
    address indexed caller,
    uint32 indexed referenceDay,
    uint256 indexed referenceBlock,
    uint256 currentSupply,
    uint256 supplyCap,
    uint256 maxStakingDuration,
    uint256 maxConsumptionRate,
    uint256 minConsumptionRate,
    uint256 mintingPeriod,
    uint256 scale,
    uint256 timestamp
);
```

