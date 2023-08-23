# ISwapProxy
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/interfaces/swapProxy/ISwapProxy.sol)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

This is the interface for Swap Proxy contract


## Functions
### domainSeparator


```solidity
function domainSeparator() external view returns (bytes32);
```

### setSilicaFactory


```solidity
function setSilicaFactory(address _silicaFactoryAddress) external;
```

### fillBuyOrder


```solidity
function fillBuyOrder(
    OrderLib.BuyOrder calldata buyerOrder,
    bytes memory buyerSignature,
    uint256 purchaseAmount,
    uint256 additionalCollateralPercent
) external returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`buyerOrder`|`OrderLib.BuyOrder`||
|`buyerSignature`|`bytes`||
|`purchaseAmount`|`uint256`|- in resource units e.g. H/s|
|`additionalCollateralPercent`|`uint256`|- added on top of base 10%, e.g. if `additionalCollateralPercent = 20` then seller will put 30% collateral.|


### fillSellOrder


```solidity
function fillSellOrder(OrderLib.SellOrder calldata sellerOrder, bytes memory sellerSignature, uint256 amount)
    external
    returns (address);
```

### routeBuy


```solidity
function routeBuy(OrderLib.SellOrder calldata sellerOrder, bytes memory sellerSignature, uint256 amount)
    external
    returns (address);
```

### isBuyOrderCancelled

Function to check if an order is canceled


```solidity
function isBuyOrderCancelled(bytes32 orderHash) external view returns (bool);
```

### isSellOrderCancelled


```solidity
function isSellOrderCancelled(bytes32 orderHash) external view returns (bool);
```

### getBudgetConsumedFromOrderHash

Function to return budget consumed by a buy order


```solidity
function getBudgetConsumedFromOrderHash(bytes32 orderHash) external view returns (uint256);
```

### getSilicaAddressFromSellOrderHash

Function to return the Silica Address created from a sell order


```solidity
function getSilicaAddressFromSellOrderHash(bytes32 orderHash) external view returns (address);
```

### cancelBuyOrder


```solidity
function cancelBuyOrder(OrderLib.BuyOrder calldata order, bytes memory signature) external;
```

### cancelSellOrder


```solidity
function cancelSellOrder(OrderLib.SellOrder calldata order, bytes memory signature) external;
```

## Events
### SellOrderFilled

```solidity
event SellOrderFilled(
    address silicaAddress, bytes32 orderHash, address signerAddress, address matcherAddress, uint256 purchaseAmount
);
```

### BuyOrderFilled

```solidity
event BuyOrderFilled(
    address silicaAddress, bytes32 orderHash, address signerAddress, address matcherAddress, uint256 purchaseAmount
);
```

### SellOrderCancelled

```solidity
event SellOrderCancelled(address signerAddress, bytes32 orderHash);
```

### BuyOrderCancelled

```solidity
event BuyOrderCancelled(address signerAddress, bytes32 orderHash);
```

