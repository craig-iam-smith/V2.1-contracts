# PayoutMath
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/libraries/math/PayoutMath.sol)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

Calculations for when buyer initiates default


## State Variables
### SCALING_FACTOR

```solidity
uint256 internal constant SCALING_FACTOR = 1e8;
```


### FIXED_POINT_SCALE_VALUE

```solidity
uint128 internal constant FIXED_POINT_SCALE_VALUE = 10 ** 14;
```


### FIXED_POINT_BASE

```solidity
uint128 internal constant FIXED_POINT_BASE = 10 ** 6;
```


### HAIRCUT_BASE_PCT

```solidity
uint32 internal constant HAIRCUT_BASE_PCT = 80;
```


## Functions
### _getHaircut

Returns haircut in fixed-point (base = 100000000 = 1).

*Granting 6 decimals precision. 1 - (0.8) * (day/contract)^3*


```solidity
function _getHaircut(uint256 _numDepositsCompleted, uint256 _contractNumberOfDeposits)
    internal
    pure
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_numDepositsCompleted`|`uint256`|The number of days on which deposits have been successfully completed|
|`_contractNumberOfDeposits`|`uint256`|The number of days on which deposits are to be completed in total in the contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: Haircut|


### _getRewardTokenPayoutToBuyerOnDefault

Calculates reward given to buyer when contract defaults.

*result = tokenBalance * (totalReward / hashrate)*


```solidity
function _getRewardTokenPayoutToBuyerOnDefault(
    uint256 _buyerTokenBalance,
    uint256 _totalRewardDelivered,
    uint256 _totalSilicaMinted
) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_buyerTokenBalance`|`uint256`|The Silica balance of the buyer|
|`_totalRewardDelivered`|`uint256`|The balance of reward tokens delivered by the seller|
|`_totalSilicaMinted`|`uint256`|The total amount of Silica that have been minted|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: The number of reward tokens to be transferred to the buyer on event of contract default|


### _getPaymentTokenPayoutToBuyerOnDefault

Calculates payment returned to buyer when contract defaults.

*result =  haircut * totalpayment tokenBalance / hashrateSold*


```solidity
function _getPaymentTokenPayoutToBuyerOnDefault(
    uint256 _buyerTokenBalance,
    uint256 _totalUpfrontPayment,
    uint256 _totalSilicaMinted,
    uint256 _haircut
) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_buyerTokenBalance`|`uint256`|The Silica balance of the buyer|
|`_totalUpfrontPayment`|`uint256`|The amount of payment tokens made at contract start|
|`_totalSilicaMinted`|`uint256`|The total amount of Silica that have been minted|
|`_haircut`|`uint256`| The haircut, see _getHaircut()|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: The amount of payment tokens to be sent to buyer in the event of a contract default|


### _getRewardPayoutToSellerOnDefault

Calculates reward given to seller when contract defaults.


```solidity
function _getRewardPayoutToSellerOnDefault(uint256 _totalUpfrontPayment, uint256 _haircutPct)
    internal
    pure
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_totalUpfrontPayment`|`uint256`|The amount of payment tokens made at contract start|
|`_haircutPct`|`uint256`|The scaled haircut percent|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: Reward token amount to be sent to seller in event of contraact default|


### _calculateReservedPrice

Calculaed the Reserved Price for a contract


```solidity
function _calculateReservedPrice(uint256 unitPrice, uint256 resourceAmount, uint256 numDeposits, uint256 decimals)
    internal
    pure
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unitPrice`|`uint256`|The price per unit|
|`resourceAmount`|`uint256`|The amount of underlying resource|
|`numDeposits`|`uint256`|The number of deposits required in the contract|
|`decimals`|`uint256`|The number of decimals of the Silica|


### _getBuyerRewardPayout

Calculated the amount of reward tokens to be sent to the buyer


```solidity
function _getBuyerRewardPayout(uint256 rewardDelivered, uint256 buyerBalance, uint256 resourceAmount)
    internal
    pure
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`rewardDelivered`|`uint256`|The amount of reward tokens deposited|
|`buyerBalance`|`uint256`|The Silica balance of the buyer address|
|`resourceAmount`|`uint256`|The amount of underlying resource|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: The amount of reward tokens to be paid to the buyer|


