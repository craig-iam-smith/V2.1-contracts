pragma solidity >=0.8.5;

import "../../OracleEthStaking.sol";

import "../CheatCodes.t.sol";

/// Thin wrapper over an instance of Oracle and HEVM
/// Methods to override state of Oracle.
/// A good candidate for some assembly code, but for now, keep it simple.
library OracleEthStakingStorage {
    address constant HEVM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    CheatCodes constant cheats = CheatCodes(HEVM_ADDRESS);

    /// SLOT 0 ///

    // roles

    /// SLOT 1 ///
    function setLastIndexedDay(OracleEthStaking self, uint32 _lastIndexedDay) public {
        cheats.store(address(self), bytes32(uint256(1)), bytes32(abi.encodePacked(uint224(0), _lastIndexedDay)));
    }

    /// SLOT 2 ///
    function setIndexAtDay(
        OracleEthStaking self,
        uint32 _day,
        OracleEthStaking.AlkimiyaEthStakingIndex memory _index
    ) public {
        bytes32 structLocation = keccak256(bytes.concat(abi.encode(_day), abi.encode(2)));

        bytes32 slot0 = bytes32(abi.encodePacked(_index.baseRewardPerIncrementPerDay));
        bytes32 slot1 = bytes32(abi.encodePacked(_index.burnFee));
        bytes32 slot2 = bytes32(abi.encodePacked(_index.priorityFee));
        bytes32 slot3 = bytes32(abi.encodePacked(_index.burnFeeNormalized));
        bytes32 slot4 = bytes32(abi.encodePacked(_index.priorityFeeNormalized));
        bytes32 slot5 = bytes32(abi.encodePacked(_index.timestamp));

        cheats.store(address(self), structLocation, slot0);

        uint256 newLocation = uint256(structLocation); // lazy addition - convert to uint256 and back
        cheats.store(address(self), bytes32(newLocation + 1), slot1);
        cheats.store(address(self), bytes32(newLocation + 2), slot2);
        cheats.store(address(self), bytes32(newLocation + 3), slot3);
        cheats.store(address(self), bytes32(newLocation + 4), slot4);
        cheats.store(address(self), bytes32(newLocation + 5), slot5);
    }
}
