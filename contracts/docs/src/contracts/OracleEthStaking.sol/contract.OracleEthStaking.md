# OracleEthStaking
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/OracleEthStaking.sol)

**Inherits:**
AccessControl, [IOracleEthStaking](/contracts/interfaces/oracle/oracleEthStaking/IOracleEthStaking.sol/interface.IOracleEthStaking.md)

**Author:**
Alkimiya Team

This is the ETH Staking Oracle contract


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
mapping(uint256 day => AlkimiyaEthStakingIndex index) private index;
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
    uint256 _referenceDay,
    uint256 _baseRewardPerIncrementPerDay,
    uint256 _burnFee,
    uint256 _priorityFee,
    uint256 _burnFeeNormalized,
    uint256 _priorityFeeNormalized,
    bytes calldata signature
) public returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_referenceDay`|`uint256`|The day to query|
|`_baseRewardPerIncrementPerDay`|`uint256`|The base reward|
|`_burnFee`|`uint256`|Total burn fee from all blocks of the day|
|`_priorityFee`|`uint256`|Total priority fee from all blocks of the day|
|`_burnFeeNormalized`|`uint256`|Sum(burnFee_per_epoch/total_staked_eth_per_epoch)|
|`_priorityFeeNormalized`|`uint256`|Sum(priorityFee_per_epoch/total_staked_eth_per_epoch)|
|`signature`|`bytes`|Signature of oracle|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool: Successful update of index has occured|


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
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_referenceDay`|`uint256`|The day to query the index for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`referenceDay`|`uint256`|The day the index was written on|
|`baseRewardPerIncrementPerDay`|`uint256`|The base reward|
|`burnFee`|`uint256`|Total burn fee from all blocks of the day|
|`priorityFee`|`uint256`|Total priority fee from all blocks of the day|
|`burnFeeNormalized`|`uint256`|Sum(burnFee_per_epoch/total_staked_eth_per_epoch)|
|`priorityFeeNormalized`|`uint256`|Sum(priorityFee_per_epoch/total_staked_eth_per_epoch)|
|`timestamp`|`uint256`||


### getInRange

Function to return array of oracle data between firstday and lastday (inclusive)


```solidity
function getInRange(uint256 _firstDay, uint256 _lastDay)
    external
    view
    returns (uint256[] memory baseRewardPerIncrementPerDayArray);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_firstDay`|`uint256`|The starting day whose index is to be returned|
|`_lastDay`|`uint256`|The final day whose index is to be returned|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`baseRewardPerIncrementPerDayArray`|`uint256[]`|an array of base reward values|


### isDayIndexed

Function to check if Oracle is updated on a given day

*Days for which function calls return true have an AlkimiyaIndex entry*


```solidity
function isDayIndexed(uint256 _referenceDay) external view override returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_referenceDay`|`uint256`|The day to check that the Oracle has an entry for|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool: Was the day indexed|


### getLastIndexedDay

Function to return the latest day on which the Oracle was updated


```solidity
function getLastIndexedDay() external view override returns (uint32);
```

## Structs
### AlkimiyaEthStakingIndex

```solidity
struct AlkimiyaEthStakingIndex {
    uint256 baseRewardPerIncrementPerDay;
    uint256 burnFee;
    uint256 priorityFee;
    uint256 burnFeeNormalized;
    uint256 priorityFeeNormalized;
    uint256 timestamp;
}
```

