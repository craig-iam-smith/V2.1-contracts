# OracleRegistry
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/OracleRegistry.sol)

**Inherits:**
Ownable, [IOracleRegistry](/contracts/interfaces/oracle/IOracleRegistry.sol/interface.IOracleRegistry.md)

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/


## State Variables
### oracleRegistry

```solidity
mapping(address token => mapping(uint256 commodityType => address oracle)) public oracleRegistry;
```


## Functions
### getOracleAddress

Function to return the list of Oracle addresses


```solidity
function getOracleAddress(address _token, uint256 _oracleType) public view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|The address of the payment token|
|`_oracleType`|`uint256`|The commodity type of the oracle|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the oracle contract|


### setOracleAddress

Set Oracle Addresses


```solidity
function setOracleAddress(address _token, uint256 _oracleType, address _oracleAddr) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_token`|`address`|The address of the payment token|
|`_oracleType`|`uint256`|The commodity type of the oracle|
|`_oracleAddr`|`address`|The address of the oracle contract|


