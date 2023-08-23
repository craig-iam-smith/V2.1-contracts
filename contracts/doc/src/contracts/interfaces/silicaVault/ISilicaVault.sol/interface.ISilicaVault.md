# ISilicaVault
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/interfaces/silicaVault/ISilicaVault.sol)

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

Interface for HashVault


## Functions
### deposit

Mints Vault shares to msg.sender by depositing exactly amount in payment


```solidity
function deposit(uint256 amount) external;
```

### scheduleWithdraw

Schedules a withdrawal of Vault shares that will be processed once the round completes


```solidity
function scheduleWithdraw(uint256 shares) external returns (uint256);
```

### processScheduledWithdraw

Processes a scheduled withdrawal from a previous round. Uses finalized pps for the round


```solidity
function processScheduledWithdraw() external returns (uint256 rewardPayout, uint256 paymentPayout);
```

### redeem

Buyer redeems their share of rewards


```solidity
function redeem(uint256 numShares) external;
```

### initialize

Initialize a new Silica Vault


```solidity
function initialize() external;
```

### processWithdraws

Function that Vault admin calls to process all withdraw requests of current epoch


```solidity
function processWithdraws() external returns (uint256 paymentLockup, uint256 rewardLockup);
```

### maxSwap

Function that Vault admin calls to swap the maximum amount of the rewards to stable


```solidity
function maxSwap() external;
```

### swap

Function that Vault admin calls to swap amount of rewards to stable


```solidity
function swap(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of rewards to swap|


### processDeposits

Function that Vault admin calls to proccess deposit requests at the beginning of the epoch


```solidity
function processDeposits() external returns (uint256 mintedShares);
```

### startNextRound

Function that Vault admin calls to start a new epoch


```solidity
function startNextRound() external;
```

### settleDefaultedSilica

Function that Vault admin calls to settle defaulted Silica contracts


```solidity
function settleDefaultedSilica(address silicaAddress) external returns (uint256 rewardPayout, uint256 paymentPayout);
```

### settleFinishedSilica

Function that Vault admin calls to settle finished Silica contracts


```solidity
function settleFinishedSilica(address silicaAddress) external returns (uint256 rewardPayout);
```

### purchaseSilica

Function that Vault admin calls to purchase Silica contracts


```solidity
function purchaseSilica(address silicaAddress, uint256 amount) external returns (uint256 silicaMinted);
```

### getAdmin

The address of the admin


```solidity
function getAdmin() external view returns (address);
```

