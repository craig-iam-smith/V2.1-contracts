pragma solidity 0.8.19;

import {ISilicaV2_1} from "../../interfaces/silica/ISilicaV2_1.sol";
import {AbstractSilicaV2_1} from "../../AbstractSilicaV2_1.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";
import "../../test/CheatCodes.t.sol";
import "../../../lib/forge-std/src/console.sol";

/// Thin wrapper over an instance of SilicaV2.1 and HEVM
/// Methods to override state of SilicaV2.1
library SilicaV2_1Storage {
    address constant HEVM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    CheatCodes constant cheats = CheatCodes(HEVM_ADDRESS);

    function setBalance(
        ISilicaV2_1 self,
        address _address,
        uint256 _balance
    ) public {
        cheats.store(address(self), keccak256(bytes.concat(abi.encode(_address), (abi.encode(0)))), bytes32(_balance));
    }

    function setTotalSupply(ISilicaV2_1 self, uint256 _totalSupply) public {
        cheats.store(address(self), bytes32(uint256(2)), bytes32(_totalSupply));
    }

    function setRewardToken(AbstractSilicaV2_1 self, address _rewardToken) public {
        bytes32 stateVar = bytes32(
            abi.encodePacked(uint64(0), uint16(0), _rewardToken)
        );
        cheats.store(address(self), bytes32(uint256(5)), stateVar);
    }

    function setPaymentToken(ISilicaV2_1 self, address _paymentToken) public {
        bytes32 stateVar = bytes32(abi.encodePacked(uint96(0), _paymentToken));
        cheats.store(address(self), bytes32(uint256(6)), stateVar);
    }

    function setOracleRegistry(ISilicaV2_1 self, address _oracleRegistry) public {
        bytes32 stateVar = bytes32(abi.encodePacked(uint96(0), _oracleRegistry));
        cheats.store(address(self), bytes32(uint256(7)), stateVar);
    }

    function setOwner(AbstractSilicaV2_1 self, address _owner) public {
        bytes32 stateVar = bytes32(
            abi.encodePacked(uint32(self.lastDueDay()), uint32(self.firstDueDay()), uint32(self.finishDay()), _owner)
        );
        cheats.store(address(self), bytes32(uint256(8)), stateVar);
    }

    function setFinishDay(AbstractSilicaV2_1 self, uint32 _finishDay) public {
        bytes32 stateVar = bytes32(
            abi.encodePacked(uint32(self.lastDueDay()), uint32(self.firstDueDay()), _finishDay, address(self.owner()))
        );
        cheats.store(address(self), bytes32(uint256(8)), stateVar);
    }

    function setFirstDueDay(AbstractSilicaV2_1 self, uint32 _firstDueDay) public {
        bytes32 stateVar = bytes32(
            abi.encodePacked(uint32(self.lastDueDay()), _firstDueDay,
            uint32(self.finishDay()),address(self.owner()))
        );
        cheats.store(address(self), bytes32(uint256(8)), stateVar);
    }

    function setLastDueDay(AbstractSilicaV2_1 self, uint32 _lastDueDay) public {
        bytes32 stateVar = bytes32(
            abi.encodePacked(_lastDueDay, uint32(self.firstDueDay()), uint32(self.finishDay()), address(self.owner()))
        );
        cheats.store(address(self), bytes32(uint256(8)), stateVar);
    }

    function setSilicaFactory(AbstractSilicaV2_1 self, address _silicaFactory) public {
        bytes32 stateVar = bytes32(abi.encodePacked(uint56(0),
        bool(self.didSellerCollectPayout()), uint32(self.defaultDay()), _silicaFactory));
        cheats.store(address(self), bytes32(uint256(9)), stateVar);
    }

    function setDefaultDay(AbstractSilicaV2_1 self, uint32 _defaultDay) public {
        bytes32 stateVar = bytes32(
            abi.encodePacked(uint56(0),
        bool(self.didSellerCollectPayout()), _defaultDay, address(self.silicaFactory()))
        );
        cheats.store(address(self), bytes32(uint256(9)), stateVar);
    }

    function setDidSellerCollectPayout(AbstractSilicaV2_1 self, bool _didSellerCollectPayout) public {
        bytes32 stateVar = bytes32(
            abi.encodePacked(uint56(0),
        _didSellerCollectPayout, uint32(self.defaultDay()), address(self.silicaFactory()))
        );
        cheats.store(address(self), bytes32(uint256(9)), stateVar);
    }

    function setStatus(AbstractSilicaV2_1 self, SilicaV2_1Types.Status _status) public {
        bytes32 stateVar = bytes32(
            abi.encodePacked(_status, uint24(0), uint24(0),
        bool(self.didSellerCollectPayout()), uint32(self.defaultDay()), address(self.silicaFactory()))
        );
        cheats.store(address(self), bytes32(uint256(9)), stateVar);
    }

    function setInitialCollateral(ISilicaV2_1 self, uint256 _initialCollateral) public {
        cheats.store(address(self), bytes32(uint256(10)), bytes32(_initialCollateral));
    }

    function setResourceAmount(ISilicaV2_1 self, uint256 _resourceAmount) public {
        cheats.store(address(self), bytes32(uint256(11)), bytes32(_resourceAmount));
    }

    function setReservedPrice(ISilicaV2_1 self, uint256 _reservedPrice) public {
        cheats.store(address(self), bytes32(uint256(12)), bytes32(_reservedPrice));
    }

    function setRewardDelivered(ISilicaV2_1 self, uint256 _rewardDelivered) public {
        cheats.store(address(self), bytes32(uint256(13)), bytes32(_rewardDelivered));
    }

    function setTotalUpfrontPayment(ISilicaV2_1 self, uint256 _totalUpFrontPayment) public {
        cheats.store(address(self), bytes32(uint256(14)), bytes32(_totalUpFrontPayment));
    }

    function setRewardExcess(ISilicaV2_1 self, uint256 _rewardExcess) public {
        cheats.store(address(self), bytes32(uint256(15)), bytes32(_rewardExcess));
    }
}
