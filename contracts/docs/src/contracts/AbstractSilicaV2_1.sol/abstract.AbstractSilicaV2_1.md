# AbstractSilicaV2_1
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/AbstractSilicaV2_1.sol)

**Inherits:**
ERC20, Initializable, [ISilicaV2_1](/contracts/interfaces/silica/ISilicaV2_1.sol/interface.ISilicaV2_1.md), [SilicaV2_1Storage](/contracts/storage/SilicaV2_1Storage.sol/abstract.SilicaV2_1Storage.md)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

This is the base to be inherited & implemented by Silica contracts


## State Variables
### DAYS_BETWEEN_DD_AND_FDD
Number of days between deploymentDay and firstDueDay


```solidity
uint256 internal constant DAYS_BETWEEN_DD_AND_FDD = 2;
```


## Functions
### onlyBuyers


```solidity
modifier onlyBuyers();
```

### onlyOpen


```solidity
modifier onlyOpen();
```

### onlyExpired


```solidity
modifier onlyExpired();
```

### onlyDefaulted


```solidity
modifier onlyDefaulted();
```

### onlyFinished


```solidity
modifier onlyFinished();
```

### onlyOwner


```solidity
modifier onlyOwner();
```

### onlyOnePayout


```solidity
modifier onlyOnePayout();
```

### initialize

Initialize a new SilicaV2_1

*Sets the state of the new SilicaV2_1 clone*


```solidity
function initialize(InitializeData calldata initializeData) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initializeData`|`InitializeData`|The struct to which to set the Silica's state|


### _calculateReservedPrice

Calculate the Reserved Price of the silica


```solidity
function _calculateReservedPrice(uint256 unitPrice, uint256 numDeposits, uint256 _decimals, uint256 _resourceAmount)
    internal
    pure
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unitPrice`|`uint256`|The price per unit|
|`numDeposits`|`uint256`|The number of payments to be made during contract|
|`_decimals`|`uint256`|The number of decimals of the SilicaV2_1|
|`_resourceAmount`|`uint256`|The quantity of the underlying resource|


### getStatus

Returns the status of the contract


```solidity
function getStatus() public view returns (SilicaV2_1Types.Status);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SilicaV2_1Types.Status`|SilicaV2_1Types.Status The current state of the Silica|


### isOpen

Check if contract is in open state


```solidity
function isOpen() public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool: True is contract status is open state|


### isExpired

Check if contract is in expired state


```solidity
function isExpired() public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool: True is contract status is expired state|


### isDefaulted

Check if contract is in defaulted state


```solidity
function isDefaulted() public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool: True is contract status is defaulted state|


### getDayOfDefault

Returns the day of default

*If X is returned, then the contract has paid X - firstDueDay payments.*


```solidity
function getDayOfDefault() public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: Day of default (if defaulted)|


### _tryDefaultContract

Function to set a contract as default

*If the contract is not defaulted, revert*


```solidity
function _tryDefaultContract() internal;
```

### _defaultContract

Snapshots variables necessary to perform default settlements.

*This tx should only happen once in the Silica's lifetime.*


```solidity
function _defaultContract(uint256 _dayOfDefault, uint256 silicaRewardBalance, uint256 _totalRewardDelivered) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_dayOfDefault`|`uint256`|The day on which default conditions were met|
|`silicaRewardBalance`|`uint256`|The balance of reward tokens in the Silica|
|`_totalRewardDelivered`|`uint256`|The total amount of reward that was deilivered|


### isRunning

Check if the contract is in running state


```solidity
function isRunning() public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool: True if the contract status is Running|


### isFinished

Check if contract is in finished state


```solidity
function isFinished() public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool: True if the contract status is Finished|


### _tryFinishContract

Function to set a contract status as Finished

*If the contract hasn't finished, revert*


```solidity
function _tryFinishContract() internal;
```

### _finishContract

Snapshots variables necessary to perform settlements

*This tx should only happen once in the Silica's lifetime*


```solidity
function _finishContract(uint256 _finishDay, uint256 silicaRewardBalance, uint256 _totalRewardDelivered) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_finishDay`|`uint256`|Day on which the contract finish conditions were met|
|`silicaRewardBalance`|`uint256`|The reward token balance of the Silica|
|`_totalRewardDelivered`|`uint256`|The amount of reward which was deilivered|


### getDaysAndRewardFulfilled

Function to get the last day fulfilled and reward delivered


```solidity
function getDaysAndRewardFulfilled() external view returns (uint256 lastDayFulfilled, uint256 rewardDelivered);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lastDayFulfilled`|`uint256`|The final day on which rewards were deilvered|
|`rewardDelivered`|`uint256`|The amount of balance of the reward token that has been deilvered by the seller|


### _getDaysAndRewardFulfilled

Returns the number of days N fulfilled by this contract, as well as the reward delivered for all N days


```solidity
function _getDaysAndRewardFulfilled(uint256 _rewardBalance, uint256 _firstDueDay, uint256 _lastDayContractOwesReward)
    internal
    view
    returns (uint256 lastDayFulfilled, uint256 rewardDelivered);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_rewardBalance`|`uint256`|Reward token balance|
|`_firstDueDay`|`uint256`|Day from which reward deposits have been required|
|`_lastDayContractOwesReward`|`uint256`|Final day reward deposits are due|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lastDayFulfilled`|`uint256`|The final day on which rewards were deilvered|
|`rewardDelivered`|`uint256`|The amount of balance of the reward token that has been deilvered by the seller|


### getRewardDeliveredSoFar

Function returns the accumulative rewards delivered


```solidity
function getRewardDeliveredSoFar() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: Accumulative rewards delivered|


### getLastDayContractOwesReward

Function returns the last day contract needs to deliver rewards


```solidity
function getLastDayContractOwesReward(uint256 _lastDueDay, uint256 lastIndexedDay) public pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_lastDueDay`|`uint256`|The Final day reward deposits are due|
|`lastIndexedDay`|`uint256`|The most recent day that has oracle data|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: The last day reward deposits are due|


### _getCollateralLocked

Function returns the Collateral Locked on the day inputed


```solidity
function _getCollateralLocked(uint256 day) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`day`|`uint256`|The day for which to query the collateral value|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: Collateral Locked on the day inputed|


### _getInitialCollateralAfterRelease

Function that calculate the collateral based on purchased amount after contract starts


```solidity
function _getInitialCollateralAfterRelease() internal view returns (uint256);
```

### _getCollateralUnlockDays

Function that calculates the dates collateral gets partial release


```solidity
function _getCollateralUnlockDays(uint256 _firstDueDay)
    internal
    view
    returns (uint256 initCollateralReleaseDay, uint256 finalCollateralReleaseDay);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_firstDueDay`|`uint256`|The first day on which reward deposits were required|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`initCollateralReleaseDay`|`uint256`|The first day collateral is released|
|`finalCollateralReleaseDay`|`uint256`|The last day collateral is released|


### getRewardDueNextOracleUpdate

Function returns the rewards amount the seller needs deliver for next Oracle update


```solidity
function getRewardDueNextOracleUpdate() external view returns (uint256 rewardDueNextOracleUpdate);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardDueNextOracleUpdate`|`uint256`|Reward amount due to be deposited at next Oracle write operation|


### deposit

Processes a buyer's upfront payment to purchase hashpower/staking using paymentTokens.
Silica is minted proportional to purchaseAmount and transfered to buyer.

*confirms the buyer's payment, mint the Silicas and transfer the tokens.*


```solidity
function deposit(uint256 amountSpecified) external onlyOpen returns (uint256 mintAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amountSpecified`|`uint256`|The amount to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`mintAmount`|`uint256`|The amount of Silica tokens that were minted|


### proxyDeposit

Processes a buyer's upfront payment to purchase hashpower/staking using paymentTokens.
Silica is minted proportional to purchaseAmount and transfered to the address specified _to.

*Confirms the buyer's payment, mint the Silicas and transfer the tokens.*


```solidity
function proxyDeposit(address _to, uint256 amountSpecified) external onlyOpen returns (uint256 mintAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address`|The address to send the minted Silica to|
|`amountSpecified`|`uint256`|The amount to deposit|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`mintAmount`|`uint256`|The amount of Silica tokens that were minted|


### _deposit

Internal function to process buyer's deposit


```solidity
function _deposit(address from, address to, uint256 _totalSupply, uint256 amountSpecified)
    internal
    returns (uint256 mintAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address of the sender|
|`to`|`address`|The address of the recipient|
|`_totalSupply`|`uint256`|Current amount of Silica|
|`amountSpecified`|`uint256`|The amount to transfer|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`mintAmount`|`uint256`|The amount of Silica tokens minted|


### _getMintAmount

Function that returns the minted Silica amount from purchase amount


```solidity
function _getMintAmount(uint256 consensusResource, uint256 purchaseAmount, uint256 _reservedPrice)
    internal
    pure
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`consensusResource`|`uint256`|The amount ofunderlying resource of the contract|
|`purchaseAmount`|`uint256`|The amount purchased|
|`_reservedPrice`|`uint256`|The calculated rerserved price, see _calculateReservedPrice()|


### _transferPaymentTokenFrom

Internal function to safely transfer payment token


```solidity
function _transferPaymentTokenFrom(address from, address to, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The sender address|
|`to`|`address`|The recipient address|
|`amount`|`uint256`|The amount of payment token to transfer|


### buyerCollectPayout

Function that buyer calls to collect reward when silica is finished


```solidity
function buyerCollectPayout() external onlyFinished onlyBuyers returns (uint256 rewardPayout);
```

### _transferBuyerPayoutOnFinish

Internal function to process rewards to Buyer when contract is Finished

*Uses PayoutMath library*


```solidity
function _transferBuyerPayoutOnFinish(address buyerAddress, uint256 buyerBalance)
    internal
    returns (uint256 rewardPayout);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`buyerAddress`|`address`|The address of the resource buyer|
|`buyerBalance`|`uint256`|The amount of Silica the buyer holds|


### _transferRewardToken

Internal function to safely transfer rewards to Buyer


```solidity
function _transferRewardToken(address to, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address of the recipient of the reward tokens|
|`amount`|`uint256`|The number of reward tokens to send|


### buyerCollectPayoutOnDefault

Function that buyer calls to settle defaulted contract

*This function can only be called by the buyers when the contract is in the defaulted state*


```solidity
function buyerCollectPayoutOnDefault()
    external
    onlyDefaulted
    onlyBuyers
    returns (uint256 rewardPayout, uint256 paymentPayout);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardPayout`|`uint256`|The amount of reward tokens sent to buyer|
|`paymentPayout`|`uint256`|The amount of payment tokens sent to buyer|


### _transferBuyerPayoutOnDefault

Internal funtion to process rewards and payment return to Buyer when contract is default


```solidity
function _transferBuyerPayoutOnDefault(address buyerAddress, uint256 buyerBalance)
    internal
    returns (uint256 rewardPayout, uint256 paymentPayout);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardPayout`|`uint256`|The amount of reward tokens sent to buyer|
|`paymentPayout`|`uint256`|The amount of payment tokens sent to buyer|


### _transferPaymentToken

Internal funtion to safely transfer payment return to Buyer


```solidity
function _transferPaymentToken(address to, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address of the recipient of the payment token transfer|
|`amount`|`uint256`|The amount of payment tokens to transfer to the to address|


### getOwner

Gets the owner of silica


```solidity
function getOwner() external view override returns (address);
```

### getRewardToken

Gets reward token address


```solidity
function getRewardToken() external view override returns (address);
```

### getPaymentToken

Gets the Payment token address


```solidity
function getPaymentToken() external view override returns (address);
```

### getLastDueDay

Returns the last day of reward the seller is selling with this contract


```solidity
function getLastDueDay() external view override returns (uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32: The last day of reward the seller is selling with this contract|


### sellerCollectPayout

Function seller calls to settle finished silica

*Only the owner(seller) can call this function when the contract is in the finished state*

*This function can only be called once*


```solidity
function sellerCollectPayout()
    external
    onlyOwner
    onlyFinished
    onlyOnePayout
    returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`paymentTokenPayout`|`uint256`|The nunber of payment tokens transferred to the seller address|
|`rewardTokenExcess`|`uint256`|The number of reward tokens left in the contract transferred to the seller address|


### sellerCollectPayoutDefault

Function seller calls to settle defaulted contract

*Only the owner(seller) can call this function when the contract is in the defaulted state*

*This function can only be called once*


```solidity
function sellerCollectPayoutDefault()
    external
    onlyOwner
    onlyDefaulted
    onlyOnePayout
    returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`paymentTokenPayout`|`uint256`|The nunber of payment tokens transferred to the seller address|
|`rewardTokenExcess`|`uint256`|The number of reward tokens left in the contract transferred to the seller address|


### sellerCollectPayoutExpired

Function seller calls to settle expired contract

*only the owner(seller) can call this function when the contract is in the expired state*

*This function can only be called once*


```solidity
function sellerCollectPayoutExpired() external onlyExpired onlyOwner returns (uint256 rewardTokenPayout);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardTokenPayout`|`uint256`|The nunber of payment tokens transferred to the seller address|


### _transferPaymentToSeller

Internal funtion to safely transfer payment to Seller


```solidity
function _transferPaymentToSeller(uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The number of payment tokens to transfer to Seller|


### _transferRewardToSeller

Internal funtion to safely transfer excess reward to Seller


```solidity
function _transferRewardToSeller(uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The number of reward tokens to transfer to Seller|


### _getRewardDueOnDay

Function to return the reward due on a given day

*This function is to be overridden by derived Silica contracts*


```solidity
function _getRewardDueOnDay(uint256 _day) internal view virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_day`|`uint256`|The day to query the reward due on|


### _getLastIndexedDay

Function to return the last day silica is synced with Oracle

*This function is to be overridden by derived Silica contracts*


```solidity
function _getLastIndexedDay() internal view virtual returns (uint32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint32`|uint32: Last day for which there is Oracle data|


### _getRewardDueInRange

Function to return total rewards due between _firstday (inclusive) and _lastday (inclusive)

*This function is to be overridden by derived Silica contracts*


```solidity
function _getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view virtual returns (uint256[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_firstDay`|`uint256`|The start day to query from|
|`_lastDay`|`uint256`|The end day to query until|


### getReservedPrice

Function to return contract reserved price


```solidity
function getReservedPrice() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint256: The reserved price|


