# Oracle
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/Oracle.sol)

**Inherits:**
AccessControl, [IOracle](/contracts/interfaces/oracle/IOracle.sol/interface.IOracle.md)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

This is the Reward Token Oracle contract


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

*Creates new instance of AlkimiyaIndex corresponding to _referenceDay in index mapping*


```solidity
function updateIndex(
    uint256 _referenceDay,
    uint256 _referenceBlock,
    uint256 _hashrate,
    uint256 _reward,
    uint256 _fees,
    uint256 _difficulty,
    bytes calldata signature
) public returns (bool success);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_referenceDay`|`uint256`|The day to create AlkimiyaIndex entry for|
|`_referenceBlock`|`uint256`|The block to be referenced|
|`_hashrate`|`uint256`|The hashrate of the given day|
|`_reward`|`uint256`|The staking reward for that day|
|`_fees`|`uint256`||
|`_difficulty`|`uint256`||
|`signature`|`bytes`|The signature of the Oracle calculator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`success`|`bool`|True if index for _referenceDay has been updated|


### get

Function to return the AlkimiyaIndex on a given day

*Timestamp must be non-zero indicating that there is an entry to read*


```solidity
function get(uint256 _referenceDay)
    external
    view
    returns (
        uint256 referenceDay,
        uint256 referenceBlock,
        uint256 hashrate,
        uint256 reward,
        uint256 fees,
        uint256 difficulty,
        uint256 timestamp
    );
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_referenceDay`|`uint256`|The day whose index is to be returned|


### getInRange

Function to return array of oracle data between firstday and lastday (inclusive)

*The days passed in are inclusive values*


```solidity
function getInRange(uint256 _firstDay, uint256 _lastDay)
    external
    view
    returns (uint256[] memory hashrateArray, uint256[] memory rewardArray);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_firstDay`|`uint256`|The starting day whose index is to be returned|
|`_lastDay`|`uint256`|The final day whose index is to be returned|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`hashrateArray`|`uint256[]`|The hashrates for each day between _firstDay & _lastDay|
|`rewardArray`|`uint256[]`|The rewards for each day between _firstDay & _lastDay|


### isDayIndexed

Function to check if Oracle has been updated on a given day

*Days for which function calls return true have an AlkimiyaIndex entry*


```solidity
function isDayIndexed(uint256 _referenceDay) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_referenceDay`|`uint256`|The day to check that the Oracle has an entry for|


### getLastIndexedDay

Function to return the latest day on which the Oracle was updated


```solidity
function getLastIndexedDay() external view returns (uint32);
```

## Structs
### AlkimiyaIndex

```solidity
struct AlkimiyaIndex {
    uint32 referenceBlock;
    uint32 timestamp;
    uint128 hashrate;
    uint64 difficulty;
    uint256 reward;
    uint256 fees;
}
```

