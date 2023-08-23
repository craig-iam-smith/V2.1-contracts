# IRewardsProxy
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/interfaces/rewardsProxy/IRewardsProxy.sol)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/


## Functions
### streamRewards

Function to stream rewards to Silica contracts


```solidity
function streamRewards(StreamRequest[] calldata streamRequests) external;
```

## Events
### RewardsStreamed
Event emitted when rewards are streamed to a Silica


```solidity
event RewardsStreamed(StreamRequest[] streamRequests);
```

## Structs
### StreamRequest

```solidity
struct StreamRequest {
    address silicaAddress;
    address rToken;
    uint256 amount;
}
```

### RewardDue

```solidity
struct RewardDue {
    address silicaAddress;
    address rToken;
    uint256 amount;
}
```

