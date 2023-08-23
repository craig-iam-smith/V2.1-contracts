# OrderLib
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/libraries/OrderLib.sol)

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/


## State Variables
### BUY_ORDER_TYPEHASH

```solidity
bytes32 public constant BUY_ORDER_TYPEHASH = keccak256(
    "BuyOrder(uint8 commodityType,uint32 endDay,uint32 orderExpirationTimestamp,uint32 salt,uint256 resourceAmount,uint256 unitPrice,address signerAddress,address rewardToken,address paymentToken,address vaultAddress)"
);
```


### SELL_ORDER_TYPEHASH

```solidity
bytes32 public constant SELL_ORDER_TYPEHASH = keccak256(
    "SellOrder(uint8 commodityType,uint32 endDay,uint32 orderExpirationTimestamp,uint32 salt,uint256 resourceAmount,uint256 unitPrice,address signerAddress,address rewardToken,address paymentToken,uint256 additionalCollateralPercent)"
);
```


## Functions
### _getBuyOrderHash

Function to get the hash of a Buy Order


```solidity
function _getBuyOrderHash(OrderLib.BuyOrder memory order) internal pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order`|`OrderLib.BuyOrder`|Instance of the BuyOrder struct({ commodityType: endDay: orderExpirationTimestamp: salt: resourceAmount: unitPrice: signerAddress: rewardToken: paymentToken: vaultAddress: })|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|bytes32: Hash of the Buy Order|


### _getSellOrderHash

Function to get the hash of a Sell Order


```solidity
function _getSellOrderHash(OrderLib.SellOrder memory order) internal pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`order`|`OrderLib.SellOrder`|Instance of the SellOrder struct({ commodityType: endDay: orderExpirationTimestamp: salt: resourceAmount: unitPrice: signerAddress: rewardToken: paymentToken: additionalCollateralPercent: })|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|bytes32: Hash of the Sell Order|


### _getTypedDataHash

Function to get the typed data hash of a Buy Order


```solidity
function _getTypedDataHash(OrderLib.BuyOrder memory _order, bytes32 DOMAIN_SEPARATOR) internal pure returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_order`|`OrderLib.BuyOrder`|Instance of the BuyOrder struct({ commodityType: endDay: orderExpirationTimestamp: salt: resourceAmount: unitPrice: signerAddress: rewardToken: paymentToken: vaultAddress: })|
|`DOMAIN_SEPARATOR`|`bytes32`|The EIP721 separator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|bytes32: Hash of the Buy Order|


### _getTypedDataHash

Function to get the typed data hash of a Sell Order


```solidity
function _getTypedDataHash(OrderLib.SellOrder memory _order, bytes32 DOMAIN_SEPARATOR)
    internal
    pure
    returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_order`|`OrderLib.SellOrder`|Instance of the SellOrder struct({ commodityType: endDay: orderExpirationTimestamp: salt: resourceAmount: unitPrice: signerAddress: rewardToken: paymentToken: additionalCollateralPercent: })|
|`DOMAIN_SEPARATOR`|`bytes32`|The EIP721 separator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|bytes32: Hash of the Sell Order|


## Structs
### BuyOrder

```solidity
struct BuyOrder {
    uint8 commodityType;
    uint32 endDay;
    uint32 orderExpirationTimestamp;
    uint32 salt;
    uint256 resourceAmount;
    uint256 unitPrice;
    address signerAddress;
    address rewardToken;
    address paymentToken;
    address vaultAddress;
}
```

### SellOrder

```solidity
struct SellOrder {
    uint8 commodityType;
    uint32 endDay;
    uint32 orderExpirationTimestamp;
    uint32 salt;
    uint256 resourceAmount;
    uint256 unitPrice;
    address signerAddress;
    address rewardToken;
    address paymentToken;
    uint256 additionalCollateralPercent;
}
```

## Enums
### OrderType

```solidity
enum OrderType {
    SellerOrder,
    BuyerOrder
}
```

