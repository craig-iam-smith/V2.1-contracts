# ISilicaFactory
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/interfaces/silicaFactory/ISilicaFactory.sol)

**Inherits:**
[ISilicaFactoryEvents](/contracts/interfaces/silicaFactory/ISilicaFactoryEvents.sol/interface.ISilicaFactoryEvents.md)

**Author:**
Alkimiya team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

Interface for Silica Account for ERC20 assets

This class needs to be inherited


## Functions
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
|`_sellerAddress`|`address`|the seller address|
|`_additionalCollateralPercent`|`uint256`|- added on top of base 10%, e.g. if `additionalCollateralPercent = 20` then seller will put 30% collateral.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the contract created|


### createEthStakingSilicaV2_1

Creates a EthStaking contract


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

Creates a EthStaking contract from SwapProxy


```solidity
function proxyCreateEthStakingSilicaV2_1(
    address _rewardTokenAddress,
    address _paymentTokenAddress,
    uint256 _resourceAmount,
    uint256 _lastDueDay,
    uint256 _unitPrice,
    address _sellerAddress,
    uint256 _additionalCollateralPercent
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
|`_sellerAddress`|`address`|the seller address|
|`_additionalCollateralPercent`|`uint256`|- added on top of base 10%, e.g. if `additionalCollateralPercent = 20` then seller will put 30% collateral.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the contract created|


### getMiningSwapCollateralRequirement

Function to return the Collateral requirement for issuance for a new Mining Swap Silica


```solidity
function getMiningSwapCollateralRequirement(uint256 lastDueDay, uint256 hashrate, address rewardTokenAddress)
    external
    view
    returns (uint256);
```

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

