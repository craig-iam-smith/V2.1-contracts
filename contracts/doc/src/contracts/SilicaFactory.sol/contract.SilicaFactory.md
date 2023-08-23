# SilicaFactory
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/SilicaFactory.sol)

**Inherits:**
[ISilicaFactory](/doc/src/contracts/interfaces/silicaFactory/ISilicaFactory.sol/interface.ISilicaFactory.md)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

Factory contract for Silica Account


## State Variables
### MINING_SWAP_COMMODITY_TYPE

```solidity
uint256 internal constant MINING_SWAP_COMMODITY_TYPE = 0;
```


### ETH_STAKING_COMMODITY_TYPE

```solidity
uint256 internal constant ETH_STAKING_COMMODITY_TYPE = 2;
```


### silicaMasterV2

```solidity
address public immutable silicaMasterV2;
```


### silicaEthStakingMaster

```solidity
address public immutable silicaEthStakingMaster;
```


### oracleRegistry

```solidity
IOracleRegistry immutable oracleRegistry;
```


### swapProxy

```solidity
ISwapProxy immutable swapProxy;
```


## Functions
### onlySwapProxy


```solidity
modifier onlySwapProxy();
```

### constructor


```solidity
constructor(address _silicaMasterV2, address _silicaEthStakingMaster, address _oracleRegistry, address _swapProxy);
```

### getMiningSwapCollateralRequirement

Function to return the Collateral requirement for issuance for a new Mining Swap Silica


```solidity
function getMiningSwapCollateralRequirement(uint256 lastDueDay, uint256 hashrate, address rewardTokenAddress)
    external
    view
    returns (uint256 miningSwapCollateralRequirement);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`lastDueDay`|`uint256`|The final day of contract on which deposit is required|
|`hashrate`|`uint256`|The hashrate|
|`rewardTokenAddress`|`address`|The address of the reward token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`miningSwapCollateralRequirement`|`uint256`|The collateral requirement|


### getEthStakingCollateralRequirement

Function to return the Collateral requirement for issuance for a new Staking Swap Silica


```solidity
function getEthStakingCollateralRequirement(
    uint256 lastDueDay,
    uint256 stakedAmount,
    address rewardTokenAddress,
    uint8 decimals
) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`lastDueDay`|`uint256`|The final day of contract on which deposit is required|
|`stakedAmount`|`uint256`|The amount that has been staked|
|`rewardTokenAddress`|`address`|The address of the reward token|
|`decimals`|`uint8`|The decimals of the reward token|


### _getMiningSwapCollateralRequirement

Function to return the Collateral requirement for issuance for a new Mining Swap Silica


```solidity
function _getMiningSwapCollateralRequirement(uint256 lastDueDay, uint256 hashrate, OracleData memory oracleData)
    internal
    pure
    returns (uint256 miningSwapCollateralRequirement);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`lastDueDay`|`uint256`|The final day of contract on which deposit is required|
|`hashrate`|`uint256`|The hashrate|
|`oracleData`|`OracleData`|A instance of the OracleData struct ({ networkHashrate: networkReward: lastIndexedDate: })|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`miningSwapCollateralRequirement`|`uint256`|The collateral requirement|


### _getEthStakingCollateralRequirement

Internal Function to return the Collateral requirement for issuance for a new Staking Swap Silica


```solidity
function _getEthStakingCollateralRequirement(
    uint256 lastDueDay,
    uint256 stakedAmount,
    OracleEthStakingData memory oracleData,
    uint8 decimals
) internal pure returns (uint256 collateralReq);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`lastDueDay`|`uint256`|The final day of contract on which deposit is required|
|`stakedAmount`|`uint256`|The amount that has been staked|
|`oracleData`|`OracleEthStakingData`|An instance of the OracleEthStakingData struct ({ referenceDay: baseRewardPerIncrementPerDay: burnFee: priorityFee: burnFeeNormalized: priorityFeeNormalized: timestamp })|
|`decimals`|`uint8`||


### _getOracleData

Function to return lastest Mining Oracle data


```solidity
function _getOracleData(address rewardTokenAddress) internal view returns (OracleData memory data);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rewardTokenAddress`|`address`|The address of the reward token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`data`|`OracleData`|OracleData struct on last indexed day|


### _getOracleEthStakingData

Function to return lastest Mining Oracle data


```solidity
function _getOracleEthStakingData(address rewardTokenAddress)
    internal
    view
    returns (OracleEthStakingData memory data);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rewardTokenAddress`|`address`|The address of the reward token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`data`|`OracleEthStakingData`|OraclEthStakingData struct of last indexed day|


### _getNumDeposits

Function to return the number of deposits the contracts requires

*lastDueDay is always greater than lastIndexedDay*


```solidity
function _getNumDeposits(uint256 lastIndexedDay, uint256 lastDueDay) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`lastIndexedDay`|`uint256`|The last day on which oracle data was written to|
|`lastDueDay`|`uint256`||


### createSilicaV2_1

Creates a SilicaV2_1 contract


```solidity
function createSilicaV2_1(
    address _rewardTokenAddress,
    address _paymentTokenAddress,
    uint256 _resourceAmount,
    uint256 _lastDueDay,
    uint256 _unitPrice
) external returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_rewardTokenAddress`|`address`|The address of the token of the rewards beeing sold by the seller|
|`_paymentTokenAddress`|`address`|address of the token that can be used to buy silica from this contract|
|`_resourceAmount`|`uint256`|hashrate the seller is selling|
|`_lastDueDay`|`uint256`|the last day of rewards the seller is selling|
|`_unitPrice`|`uint256`|the price of gH/day|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the contract created|


### proxyCreateSilicaV2_1

Creates a SilicaV2_1 contract from SwapProxy


```solidity
function proxyCreateSilicaV2_1(
    address _rewardTokenAddress,
    address _paymentTokenAddress,
    uint256 _resourceAmount,
    uint256 _lastDueDay,
    uint256 _unitPrice,
    address _sellerAddress,
    uint256 _additionalCollateralPercent
) external onlySwapProxy returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_rewardTokenAddress`|`address`|The address of the token of the rewards beeing sold by the seller|
|`_paymentTokenAddress`|`address`|address of the token that can be used to buy silica from this contract|
|`_resourceAmount`|`uint256`|hashrate the seller is selling|
|`_lastDueDay`|`uint256`|the last day of rewards the seller is selling|
|`_unitPrice`|`uint256`|the price of gH/day|
|`_sellerAddress`|`address`|the seller address|
|`_additionalCollateralPercent`|`uint256`|- added on top of base 10%, e.g. if `additionalCollateralPercent = 20` then you will put 30% collateral.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the contract created|


### _createSilicaV2_1

Internal function to create a Silica V2.1


```solidity
function _createSilicaV2_1(
    address _rewardTokenAddress,
    address _paymentTokenAddress,
    uint256 _resourceAmount,
    uint256 _lastDueDay,
    uint256 _unitPrice,
    address _sellerAddress,
    uint256 _additionalCollateralPercent
) internal returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_rewardTokenAddress`|`address`|The address of the token of the rewards beeing sold by the seller|
|`_paymentTokenAddress`|`address`|address of the token that can be used to buy silica from this contract|
|`_resourceAmount`|`uint256`|hashrate the seller is selling|
|`_lastDueDay`|`uint256`|the last day of rewards the seller is selling|
|`_unitPrice`|`uint256`|the price of gH/day|
|`_sellerAddress`|`address`|the address of the resource seller|
|`_additionalCollateralPercent`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the contract created|


### createEthStakingSilicaV2_1

Creates a EthStakingSilicaV2_1 contract


```solidity
function createEthStakingSilicaV2_1(
    address _rewardTokenAddress,
    address _paymentTokenAddress,
    uint256 _resourceAmount,
    uint256 _lastDueDay,
    uint256 _unitPrice
) external returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_rewardTokenAddress`|`address`|The address of the token of the rewards beeing sold by the seller|
|`_paymentTokenAddress`|`address`|address of the token that can be used to buy silica from this contract|
|`_resourceAmount`|`uint256`|Amount of token staked generating the rewards beeing sold by the seller with this contract|
|`_lastDueDay`|`uint256`|the last day of rewards the seller is selling|
|`_unitPrice`|`uint256`|the price of stakedToken/day|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the contract created|


### proxyCreateEthStakingSilicaV2_1

Creates a EthStakingSilicaV2_1 contract from SwapProxy


```solidity
function proxyCreateEthStakingSilicaV2_1(
    address _rewardTokenAddress,
    address _paymentTokenAddress,
    uint256 _resourceAmount,
    uint256 _lastDueDay,
    uint256 _unitPrice,
    address _sellerAddress,
    uint256 _additionalCollateralPercent
) external onlySwapProxy returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_rewardTokenAddress`|`address`|The address of the token of the rewards beeing sold by the seller|
|`_paymentTokenAddress`|`address`|address of the token that can be used to buy silica from this contract|
|`_resourceAmount`|`uint256`|Amount of token staked generating the rewards beeing sold by the seller with this contract|
|`_lastDueDay`|`uint256`|the last day of rewards the seller is selling|
|`_unitPrice`|`uint256`|the price of stakedToken/day|
|`_sellerAddress`|`address`|the seller address|
|`_additionalCollateralPercent`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the contract created|


### _createEthStakingSilicaV2_1

Internal function to create a Eth Staking Silica V2.1


```solidity
function _createEthStakingSilicaV2_1(
    address _rewardTokenAddress,
    address _paymentTokenAddress,
    uint256 _resourceAmount,
    uint256 _lastDueDay,
    uint256 _unitPrice,
    address _sellerAddress,
    uint256 _additionalCollateralPercent
) internal returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_rewardTokenAddress`|`address`|The address of the token of the rewards beeing sold by the seller|
|`_paymentTokenAddress`|`address`|address of the token that can be used to buy silica from this contract|
|`_resourceAmount`|`uint256`|Amount of token staked generating the rewards beeing sold by the seller with this contract|
|`_lastDueDay`|`uint256`|the last day of rewards the seller is selling|
|`_unitPrice`|`uint256`|the price of stakedToken/day|
|`_sellerAddress`|`address`|the seller address|
|`_additionalCollateralPercent`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the contract created|


## Errors
### InvalidType

```solidity
error InvalidType();
```

### Unauthorized

```solidity
error Unauthorized();
```

## Structs
### OracleData

```solidity
struct OracleData {
    uint256 networkHashrate;
    uint256 networkReward;
    uint256 lastIndexedDay;
}
```

### OracleEthStakingData

```solidity
struct OracleEthStakingData {
    uint256 baseRewardPerIncrementPerDay;
    uint256 lastIndexedDay;
}
```

