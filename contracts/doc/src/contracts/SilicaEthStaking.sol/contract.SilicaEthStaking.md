# SilicaEthStaking
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/SilicaEthStaking.sol)

**Inherits:**
[AbstractSilicaV2_1](/doc/src/contracts/AbstractSilicaV2_1.sol/abstract.AbstractSilicaV2_1.md)

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/


## State Variables
### COMMODITY_TYPE

```solidity
uint256 public constant COMMODITY_TYPE = 2;
```


## Functions
### decimals


```solidity
function decimals() public pure override returns (uint8);
```

### constructor


```solidity
constructor() ERC20("Silica", "SLC");
```

### _getLastIndexedDay

Function to return the last day Silica was synced with Oracle


```solidity
function _getLastIndexedDay() internal view override returns (uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32: The last day the Silica was synced with the Oracle|


### _getRewardDueOnDay

Function to return the amount of rewards due by the seller to the contract on day inputed


```solidity
function _getRewardDueOnDay(uint256 _day) internal view override returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_day`|`uint256`|The day on which to query the reward|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: The reward due on the input day|


### _getRewardDueInRange

Function to return total rewards due between _firstday (inclusive) and _lastday (inclusive)

*This function is to be overridden by derived Silica contracts*


```solidity
function _getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view override returns (uint256[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_firstDay`|`uint256`|The start day to query from|
|`_lastDay`|`uint256`|The end day to query until|


### getCommodityType

Returns the commodity type the seller is selling with this contract


```solidity
function getCommodityType() external pure override returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The commodity type the seller is selling with this contract|


### getDecimals

Returns decimals of the contract


```solidity
function getDecimals() external pure override returns (uint8);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint8`|uint8: Decimals|


