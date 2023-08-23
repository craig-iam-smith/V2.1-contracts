# IOracleRegistry
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/interfaces/oracle/IOracleRegistry.sol)

**Author:**
Alkimiya Team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

Alkimiya Oracle addresses


## Functions
### getOracleAddress


```solidity
function getOracleAddress(address _token, uint256 _oracleType) external view returns (address);
```

### setOracleAddress


```solidity
function setOracleAddress(address _token, uint256 _oracleType, address _oracleAddr) external;
```

## Events
### OracleRegistered

```solidity
event OracleRegistered(address token, uint256 oracleType, address oracleAddr);
```

