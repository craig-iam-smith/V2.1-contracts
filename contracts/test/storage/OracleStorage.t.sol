pragma solidity >=0.8.5;

import "../../../lib/forge-std/src/Test.sol";
import "../../Oracle.sol";

import "../../interfaces/oracle/IOracle.sol";
import "../../interfaces/oracle/IOracleRegistry.sol";
import "../CheatCodes.t.sol";

/// Thin wrapper over an instance of Oracle and HEVM
/// Methods to override state of Oracle.
/// A good candidate for some assembly code, but for now, keep it simple.
library OracleStorage {
    address constant HEVM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    CheatCodes constant cheats = CheatCodes(HEVM_ADDRESS);

    /// SLOT 0 ///

    // roles

    /// SLOT 1 ///
    function setLastIndexedDay(Oracle self, uint32 _lastIndexedDay) public {
        cheats.store(address(self), bytes32(uint256(1)), bytes32(abi.encodePacked(uint224(0), _lastIndexedDay)));
    }

    /// SLOT 2 ///
    function setIndexAtDay(
        Oracle self,
        uint32 _day,
        Oracle.AlkimiyaIndex memory _index
    ) public {
        bytes32 structLocation = keccak256(bytes.concat(abi.encode(_day), abi.encode(2)));

        bytes32 slot0 = bytes32(abi.encodePacked(_index.difficulty, _index.hashrate, _index.timestamp, _index.referenceBlock));
        bytes32 slot1 = bytes32(abi.encodePacked(_index.reward));
        bytes32 slot2 = bytes32(abi.encodePacked(_index.fees));

        cheats.store(address(self), structLocation, slot0);

        uint256 newLocation = uint256(structLocation); // lazy addition - convert to uint256 and back
        cheats.store(address(self), bytes32(newLocation + 1), slot1);
        cheats.store(address(self), bytes32(newLocation + 2), slot2);
    }
}
