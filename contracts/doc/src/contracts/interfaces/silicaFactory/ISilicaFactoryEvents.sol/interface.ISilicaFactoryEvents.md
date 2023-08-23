# ISilicaFactoryEvents
[Git Source](https://github.com/Alkimiya/v2.1-core/tree/comments-docs/blob/ee3e12bcce8690315f313782a9d6014a1b843773/contracts/interfaces/silicaFactory/ISilicaFactoryEvents.sol)

**Author:**
Alkimiya team

_    _ _    _           _
/ \  | | | _(_)_ __ ___ (_)_   _  __ _
/ _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
/ ___ \| |   <| | | | | | | | |_| | (_| |
/_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
|___/

Contains all events emitted by a Silica contract


## Events
### NewSilicaContract
The event emited when a new Silica contract is created.


```solidity
event NewSilicaContract(address newContractAddress, ISilicaV2_1.InitializeData initializeData, uint16 commodityType);
```

