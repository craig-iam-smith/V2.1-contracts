# OraclePoS
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/OraclePoS.sol)

**Inherits:**
AccessControl, [IOraclePoS](/doc/src/contracts/interfaces/oracle/IOraclePoS.sol/interface.IOraclePoS.md)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

Alkimiya Oracle for Proof Of Stake instruments


## State Variables
### VERSION

```solidity
int8 public constant VERSION = 1;
```


### lastIndexedDay

```solidity
uint32 public lastIndexedDay;
```


### PUBLISHER_ROLE

```solidity
bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");
```


### CALCULATOR_ROLE

```solidity
bytes32 public constant CALCULATOR_ROLE = keccak256("CALCULATOR_ROLE");
```


### index

```solidity
mapping(uint256 day => AlkimiyaIndex index) private index;
```


### name

```solidity
string public name;
```


## Functions
### constructor


```solidity
constructor(string memory _name);
```

### updateIndex

Function to update Oracle Index


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
    bytes calldata signature
) external returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_referenceDay`|`uint32`|The day to map the Oracle Index update to|
|`_referenceBlock`|`uint256`|The block to map the Oracle Index update to|
|`_currentSupply`|`uint256`|The current underlying token Supply|
|`_supplyCap`|`uint256`|The max supply|
|`_maxStakingDuration`|`uint256`|The maximum duration tokens can be staked for|
|`_maxConsumptionRate`|`uint256`|The maximum consumption rate|
|`_minConsumptionRate`|`uint256`|The minimum consumption rate|
|`_mintingPeriod`|`uint256`|The duration over which minting will occur|
|`_scale`|`uint256`|The scaling factor|
|`signature`|`bytes`|The signature of the calculator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|True if the index for _refrenceDay was updated|


### get

Function to return Oracle index on given day


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
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_referenceDay`|`uint256`||


### isDayIndexed

Function to check if Oracle is updated on a given day


```solidity
function isDayIndexed(uint256 _referenceDay) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_referenceDay`|`uint256`|The day to check if there is an index for|


### getLastIndexedDay

Functino to return the latest day on which the Oracle is updated


```solidity
function getLastIndexedDay() external view returns (uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32: The most recent day there is Oracle data for|


## Structs
### AlkimiyaIndex

```solidity
struct AlkimiyaIndex {
    uint256 referenceBlock;
    uint256 currentSupply;
    uint256 supplyCap;
    uint256 maxStakingDuration;
    uint256 maxConsumptionRate;
    uint256 minConsumptionRate;
    uint256 mintingPeriod;
    uint256 scale;
    uint256 timestamp;
}
```

