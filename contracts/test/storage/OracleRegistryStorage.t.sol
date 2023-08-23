pragma solidity >=0.8.5;

import "../../../lib/forge-std/src/Test.sol";
import "../../OracleRegistry.sol";

import "../../interfaces/oracle/IOracle.sol";
import "../../interfaces/oracle/IOracleRegistry.sol";
import "../CheatCodes.t.sol";

/// Thin wrapper over an instance of Oracle and HEVM
/// Methods to override state of Oracle.
/// A good candidate for some assembly code, but for now, keep it simple.
library OracleRegistryStorage {
    address constant HEVM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    CheatCodes constant cheats = CheatCodes(HEVM_ADDRESS);

    /// SLOT 0 ///
    function setOwner(OracleRegistry self, address _address) public {
        cheats.store(address(self), bytes32(uint256(0)), bytes32(abi.encodePacked(uint96(0), _address)));
    }

    /// SLOT 1 ///
    function setOracle(
        OracleRegistry self,
        address _rewardTokenAddress,
        uint16 _commodityType,
        address _oracleAddress
    ) public {
        bytes32 structLocation1 = keccak256(bytes.concat(abi.encode(_rewardTokenAddress), abi.encode(1)));
        bytes32 structLocation2 = keccak256(bytes.concat(abi.encode(_commodityType), structLocation1));

        cheats.store(address(self), structLocation2, bytes32(abi.encodePacked(uint96(0), _oracleAddress)));
    }
}
