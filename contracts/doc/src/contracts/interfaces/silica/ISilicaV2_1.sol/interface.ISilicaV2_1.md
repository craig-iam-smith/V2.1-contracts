# ISilicaV2_1
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/interfaces/silica/ISilicaV2_1.sol)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

A Silica contract lists hashrate for sale

*The Silica interface is broken up into smaller interfaces*


## Functions
### getRewardDueNextOracleUpdate

Returns the amount of rewards the seller must have delivered before next update


```solidity
function getRewardDueNextOracleUpdate() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|rewardDueNextOracleUpdate amount of rewards the seller must have delivered before next update|


### initialize

Initializes the contract


```solidity
function initialize(InitializeData memory initializeData) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initializeData`|`InitializeData`|is the address of the token the seller is selling|


### deposit

Function called by buyer to deposit payment token in the contract in exchange for Silica tokens


```solidity
function deposit(uint256 amountSpecified) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountSpecified`|`uint256`|is the amount that the buyer wants to deposit in exchange for Silica tokens|


### proxyDeposit

Called by the swapProxy to make a deposit in the name of a buyer


```solidity
function proxyDeposit(address _to, uint256 amountSpecified) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address`|the address who should receive the Silica Tokens|
|`amountSpecified`|`uint256`|is the amount the swapProxy is depositing for the buyer in exchange for Silica tokens|


### buyerCollectPayout

Function the buyer calls to collect payout when the contract status is Finished


```solidity
function buyerCollectPayout() external returns (uint256 rewardTokenPayout);
```

### buyerCollectPayoutOnDefault

Function the buyer calls to collect payout when the contract status is Defaulted


```solidity
function buyerCollectPayoutOnDefault() external returns (uint256 rewardTokenPayout, uint256 paymentTokenPayout);
```

### sellerCollectPayout

Function the seller calls to collect payout when the contract status is Finised


```solidity
function sellerCollectPayout() external returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);
```

### sellerCollectPayoutDefault

Function the seller calls to collect payout when the contract status is Defaulted


```solidity
function sellerCollectPayoutDefault() external returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);
```

### sellerCollectPayoutExpired

Function the seller calls to collect payout when the contract status is Expired


```solidity
function sellerCollectPayoutExpired() external returns (uint256 rewardTokenPayout);
```

### getOwner

Returns the owner of this Silica


```solidity
function getOwner() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address: owner address|


### getPaymentToken

Returns the Payment Token accepted in this Silica


```solidity
function getPaymentToken() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Address: Token Address|


### getRewardToken

Returns the rewardToken address. The rewardToken is the token fo wich are made the rewards the seller is selling


```solidity
function getRewardToken() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The rewardToken address. The rewardToken is the token fo wich are made the rewards the seller is selling|


### getLastDueDay

Returns the last day of reward the seller is selling with this contract


```solidity
function getLastDueDay() external view returns (uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|The last day of reward the seller is selling with this contract|


### getCommodityType

Returns the commodity type the seller is selling with this contract


```solidity
function getCommodityType() external pure returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The commodity type the seller is selling with this contract|


### getStatus

Get the current status of the contract


```solidity
function getStatus() external view returns (SilicaV2_1Types.Status);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SilicaV2_1Types.Status`|status: The current status of the contract|


### getDayOfDefault

Returns the day of default.


```solidity
function getDayOfDefault() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|day: The day the contract defaults|


### getDaysAndRewardFulfilled


```solidity
function getDaysAndRewardFulfilled() external view returns (uint256 lastDayFulfilled, uint256 rewardDelivered);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lastDayFulfilled`|`uint256`|- number of days fulfilled|
|`rewardDelivered`|`uint256`|- reward fulfilled plus collateral|


### isOpen

Returns true if contract is in Open status


```solidity
function isOpen() external view returns (bool);
```

### isRunning

Returns true if contract is in Running status


```solidity
function isRunning() external view returns (bool);
```

### isExpired

Returns true if contract is in Expired status


```solidity
function isExpired() external view returns (bool);
```

### isDefaulted

Returns true if contract is in Defaulted status


```solidity
function isDefaulted() external view returns (bool);
```

### isFinished

Returns true if contract is in Finished status


```solidity
function isFinished() external view returns (bool);
```

### getRewardDeliveredSoFar

Returns amount of rewards delivered so far by contract


```solidity
function getRewardDeliveredSoFar() external view returns (uint256);
```

### getLastDayContractOwesReward

Returns the most recent day the contract owes in rewards

*The returned value does not indicate rewards have been fulfilled up to that day
This only returns the most recent day the contract should deliver rewards*


```solidity
function getLastDayContractOwesReward(uint256 lastDueDay, uint256 lastIndexedDay) external view returns (uint256);
```

### getReservedPrice

Returns the reserved price of the contract


```solidity
function getReservedPrice() external view returns (uint256);
```

### getDecimals

Returns decimals of the contract


```solidity
function getDecimals() external pure returns (uint8);
```

## Events
### Deposit

```solidity
event Deposit(address indexed buyer, uint256 purchaseAmount, uint256 mintedTokens);
```

### BuyerCollectPayout

```solidity
event BuyerCollectPayout(
    uint256 rewardTokenPayout, uint256 paymentTokenPayout, address buyerAddress, uint256 burntAmount
);
```

### SellerCollectPayout

```solidity
event SellerCollectPayout(uint256 paymentTokenPayout, uint256 rewardTokenExcess);
```

### StatusChanged

```solidity
event StatusChanged(SilicaV2_1Types.Status status);
```

## Structs
### InitializeData

```solidity
struct InitializeData {
    address rewardTokenAddress;
    address paymentTokenAddress;
    address oracleRegistry;
    address sellerAddress;
    uint256 dayOfDeployment;
    uint256 lastDueDay;
    uint256 unitPrice;
    uint256 resourceAmount;
    uint256 collateralAmount;
}
```

