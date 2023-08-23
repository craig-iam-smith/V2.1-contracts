/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/oracle/IOraclePoS.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title  Oracle PoS
 * @author Alkimiya Team
 * @notice Alkimiya Oracle for Proof Of Stake instruments
 */
contract OraclePoS is AccessControl, IOraclePoS {

    /*///////////////////////////////////////////////////////////////
                             State Variables
    //////////////////////////////////////////////////////////////*/

    // Constants
    int8 public constant VERSION = 1;
    uint32 public lastIndexedDay;

    bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");
    bytes32 public constant CALCULATOR_ROLE = keccak256("CALCULATOR_ROLE");

    mapping(uint256 day => AlkimiyaIndex index) private index; // key == timestamp / SECONDS_PER_DAY

    string public name;

    struct AlkimiyaIndex {
        uint256 referenceBlock;
        uint256 currentSupply;
        uint256 supplyCap;
        uint256 maxStakingDuration;
        uint256 maxConsumptionRate;
        uint256 minConsumptionRate;
        uint256 mintingPeriod;
        uint256 scale;
        uint256 timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                             Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name) {
        _setupRole(PUBLISHER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        name = _name;
    }

    /*///////////////////////////////////////////////////////////////
                         User Facing Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to update Oracle Index
    /// @param _referenceDay The day to map the Oracle Index update to
    /// @param _referenceBlock The block to map the Oracle Index update to
    /// @param _currentSupply The current underlying token Supply
    /// @param _supplyCap The max supply
    /// @param _maxStakingDuration The maximum duration tokens can be staked for
    /// @param _maxConsumptionRate The maximum consumption rate
    /// @param _minConsumptionRate The minimum consumption rate
    /// @param _mintingPeriod The duration over which minting will occur
    /// @param _scale The scaling factor
    /// @param signature The signature of the calculator
    /// @return success True if the index for _refrenceDay was updated
    function updateIndex(
        uint32  _referenceDay,
        uint256 _referenceBlock,
        uint256 _currentSupply,
        uint256 _supplyCap,
        uint256 _maxStakingDuration,
        uint256 _maxConsumptionRate,
        uint256 _minConsumptionRate,
        uint256 _mintingPeriod,
        uint256 _scale,
        bytes calldata signature
    ) external returns (bool success) {
        require(hasRole(PUBLISHER_ROLE, msg.sender), "Update not allowed to everyone");

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        _referenceDay,
                        _referenceBlock,
                        _currentSupply,
                        _supplyCap,
                        _maxStakingDuration,
                        _maxConsumptionRate,
                        _minConsumptionRate,
                        _mintingPeriod,
                        _scale
                    )
                )
            )
        );

        require(hasRole(CALCULATOR_ROLE, ECDSA.recover(messageHash, signature)), "Invalid signature");

        require(index[_referenceDay].timestamp == 0, "Information cannot be updated.");

        index[_referenceDay].timestamp = block.timestamp;
        index[_referenceDay].referenceBlock = _referenceBlock;
        index[_referenceDay].currentSupply = _currentSupply;
        index[_referenceDay].supplyCap = _supplyCap;
        index[_referenceDay].maxStakingDuration = _maxStakingDuration;
        index[_referenceDay].maxConsumptionRate = _maxConsumptionRate;
        index[_referenceDay].minConsumptionRate = _minConsumptionRate;
        index[_referenceDay].mintingPeriod = _mintingPeriod;
        index[_referenceDay].scale = _scale;

        if (_referenceDay > lastIndexedDay) {
            lastIndexedDay = _referenceDay;
        }

        emit OracleUpdate(
            msg.sender,
            _referenceDay,
            _referenceBlock,
            _currentSupply,
            _supplyCap,
            _maxStakingDuration,
            _maxConsumptionRate,
            _minConsumptionRate,
            _mintingPeriod,
            _scale,
            block.timestamp
        );

        return true;
    }

    /// @notice Function to return Oracle index on given day
    /// @param referenceDay The day to query the index of
    /// @param currentSupply The current underlying token Supply
    /// @param referenceBlock The block being referenced in lookup
    /// @param supplyCap The max supply
    /// @param maxStakingDuration The maximum duration tokens can be staked for
    /// @param maxConsumptionRate The maximum consumption rate
    /// @param minConsumptionRate The minimum consumption rate
    /// @param mintingPeriod The duration over which minting will occur
    /// @param scale The scaling factor
    function get(uint256 _referenceDay)
        external
        view
        returns (
            uint256 referenceDay,
            uint256 referenceBlock,
            uint256 currentSupply,
            uint256 supplyCap,
            uint256 maxStakingDuration,
            uint256 maxConsumptionRate,
            uint256 minConsumptionRate,
            uint256 mintingPeriod,
            uint256 scale,
            uint256 timestamp
        )
    {
        AlkimiyaIndex memory current = index[_referenceDay];
        require(index[_referenceDay].timestamp != 0, "Date not yet indexed");

        return (
            _referenceDay,
            current.referenceBlock,
            current.currentSupply,
            current.supplyCap,
            current.maxStakingDuration,
            current.maxConsumptionRate,
            current.minConsumptionRate,
            current.mintingPeriod,
            current.scale,
            current.timestamp
        );
    }

    /// @notice Function to check if Oracle is updated on a given day
    /// @param _referenceDay The day to check if there is an index for
    function isDayIndexed(uint256 _referenceDay) external view returns (bool) {
        return index[_referenceDay].timestamp != 0;
    }

    /// @notice Functino to return the latest day on which the Oracle is updated
    /// @return uint32: The most recent day there is Oracle data for
    function getLastIndexedDay() external view returns (uint32) {
        return lastIndexedDay;
    }
}
