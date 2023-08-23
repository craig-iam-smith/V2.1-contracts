# SwapProxy
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/SwapProxy.sol)

**Inherits:**
EIP712, Ownable2Step, [ISwapProxy](/doc/src/contracts/interfaces/swapProxy/ISwapProxy.sol/interface.ISwapProxy.md)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

This contract fills orders on behalf of users


## State Variables
### buyOrdersCancelled

```solidity
mapping(bytes32 orderHash => bool isCancelled) public buyOrdersCancelled;
```


### buyOrderToConsumedBudget

```solidity
mapping(bytes32 orderHash => uint256 consumedBudget) public buyOrderToConsumedBudget;
```


### sellOrdersCancelled

```solidity
mapping(bytes32 orderHash => bool isCancelled) public sellOrdersCancelled;
```


### sellOrderToSilica

```solidity
mapping(bytes32 orderHash => address silicaAddress) public sellOrderToSilica;
```


### silicaFactory

```solidity
ISilicaFactory private silicaFactory;
```


## Functions
### constructor


```solidity
constructor(string memory name) EIP712(name, "1");
```

### setSilicaFactory

Function set the address of the Silica Factory

*Only the contract owner can call this function*


```solidity
function setSilicaFactory(address _silicaFactoryAddress) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_silicaFactoryAddress`|`address`|The Silica Factory address|


### domainSeparator

Function to get the Domain Separator


```solidity
function domainSeparator() external view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|bytes32: EIP712 Domain Separator|


### fillBuyOrder

Function to fill a Buy Order


```solidity
function fillBuyOrder(
    OrderLib.BuyOrder calldata buyerOrder,
    bytes calldata buyerSignature,
    uint256 purchaseAmount,
    uint256 additionalCollateralPercent
) external returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`buyerOrder`|`OrderLib.BuyOrder`|Instance of the BuyOrder struct({ commodityType: endDay: orderExpirationTimestamp: salt: resourceAmount: unitPrice: signerAddress: rewardToken: paymentToken: vaultAddress: })|
|`buyerSignature`|`bytes`|The signature of the resource buyer|
|`purchaseAmount`|`uint256`|The amount to purchase|
|`additionalCollateralPercent`|`uint256`|Added on top of base 10%, e.g. if `additionalCollateralPercent = 20` then you will put 30% collateral.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the newly created Silica|


### routeBuy

Function to route buy


```solidity
function routeBuy(OrderLib.SellOrder calldata sellerOrder, bytes memory sellerSignature, uint256 amount)
    external
    returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sellerOrder`|`OrderLib.SellOrder`|An instance of the SellOrder struct ({ commodityType: endDay: orderExpirationTimestamp: salt: resourceAmount: unitPrice: signerAddress: rewardToken: paymentToken: additionalCollateralPercent: })|
|`sellerSignature`|`bytes`|The signature of the order seller|
|`amount`|`uint256`|The amount to purchase|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the newly created Silica|


### fillSellOrder

Function to fill a Sell  Order


```solidity
function fillSellOrder(OrderLib.SellOrder calldata sellerOrder, bytes memory sellerSignature, uint256 amount)
    external
    returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sellerOrder`|`OrderLib.SellOrder`|An instance of the SellOrder struct ({ commodityType: endDay: orderExpirationTimestamp: salt: resourceAmount: unitPrice: signerAddress: rewardToken: paymentToken: additionalCollateralPercent: })|
|`sellerSignature`|`bytes`|The signature of the order seller|
|`amount`|`uint256`|The amount to purchase|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: The address of the newly created Silica|


### cancelBuyOrder

Function to cancel a listed buy order


```solidity
function cancelBuyOrder(OrderLib.BuyOrder calldata order, bytes memory signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order`|`OrderLib.BuyOrder`|Instance of the BuyOrder struct({ commodityType: endDay: orderExpirationTimestamp: salt: resourceAmount: unitPrice: signerAddress: rewardToken: paymentToken: vaultAddress: })|
|`signature`|`bytes`|The signature of the signer|


### cancelSellOrder

Function to cancel a listed sell order


```solidity
function cancelSellOrder(OrderLib.SellOrder calldata order, bytes memory signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order`|`OrderLib.SellOrder`|Instance of the SellOrder struct({ commodityType: endDay: orderExpirationTimestamp: salt: resourceAmount: unitPrice: signerAddress: rewardToken: paymentToken: additionalCollateralPercent: })|
|`signature`|`bytes`|The signature of the signer|


### isBuyOrderCancelled

Function to check if a Buy Order is canceled


```solidity
function isBuyOrderCancelled(bytes32 orderHash) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`orderHash`|`bytes32`|The hash of the order|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool: True if order has been cancelled|


### isSellOrderCancelled

Function to check if a Sell Order is canceled


```solidity
function isSellOrderCancelled(bytes32 orderHash) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`orderHash`|`bytes32`|The hash of the order|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool: True if order has been cancelled|


### getBudgetConsumedFromOrderHash

Function to return the budget consumed by a buy order


```solidity
function getBudgetConsumedFromOrderHash(bytes32 orderHash) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`orderHash`|`bytes32`|The hash of the order|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: Budget Consumed|


### getSilicaAddressFromSellOrderHash

Function to return the Silica address created from a sell order


```solidity
function getSilicaAddressFromSellOrderHash(bytes32 orderHash) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`orderHash`|`bytes32`|The hash of the order|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The associated Silica address|


