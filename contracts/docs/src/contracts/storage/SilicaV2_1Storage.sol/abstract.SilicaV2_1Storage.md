# SilicaV2_1Storage
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/storage/SilicaV2_1Storage.sol)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |  <|  | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

This is base storage to be inherited by derived Silica contracts


## State Variables
### rewardToken

```solidity
address public rewardToken;
```


### paymentToken

```solidity
address public paymentToken;
```


### oracleRegistry

```solidity
address public oracleRegistry;
```


### owner

```solidity
address public owner;
```


### finishDay

```solidity
uint32 public finishDay;
```


### firstDueDay

```solidity
uint32 public firstDueDay;
```


### lastDueDay

```solidity
uint32 public lastDueDay;
```


### silicaFactory

```solidity
address public silicaFactory;
```


### defaultDay

```solidity
uint32 public defaultDay;
```


### didSellerCollectPayout

```solidity
bool public didSellerCollectPayout;
```


### status

```solidity
SilicaV2_1Types.Status status;
```


### initialCollateral

```solidity
uint256 public initialCollateral;
```


### resourceAmount

```solidity
uint256 public resourceAmount;
```


### reservedPrice

```solidity
uint256 public reservedPrice;
```


### rewardDelivered

```solidity
uint256 public rewardDelivered;
```


### totalUpfrontPayment

```solidity
uint256 public totalUpfrontPayment;
```


### rewardExcess

```solidity
uint256 public rewardExcess;
```


