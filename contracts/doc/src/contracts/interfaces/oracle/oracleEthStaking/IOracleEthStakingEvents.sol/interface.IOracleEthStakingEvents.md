# IOracleEthStakingEvents
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/interfaces/oracle/oracleEthStaking/IOracleEthStakingEvents.sol)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |  <|  | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

This is the interface for Proof of Stake Oracle contract


## Events
### OracleUpdate
Oracle Update Event


```solidity
event OracleUpdate(
    address indexed caller,
    uint256 indexed referenceDay,
    uint256 timestamp,
    uint256 baseRewardPerIncrementPerDay,
    uint256 burnFee,
    uint256 priorityFee,
    uint256 burnFeeNormalized,
    uint256 priorityFeeNormalized
);
```

