/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
 * */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title  Alkimiya OraclePoS
 * @author Alkimiya Team
 * @notice This is the interface for Proof of Stake Oracle contract
 * */
interface IOraclePoS {
    event OracleUpdate(
        address indexed caller,
        uint32 indexed referenceDay,
        uint256 indexed referenceBlock,
        uint256 currentSupply,
        uint256 supplyCap,
        uint256 maxStakingDuration,
        uint256 maxConsumptionRate,
        uint256 minConsumptionRate,
        uint256 mintingPeriod,
        uint256 scale,
        uint256 timestamp
    );

    /**
     * @notice Return the Network data on a given day is updated to Oracle
     */
    function isDayIndexed(uint256 _referenceDay) external view returns (bool);

    /**
     * @notice Return the last day on which the Oracle is updated
     */
    function getLastIndexedDay() external view returns (uint32);

    /**
     * @notice Update the Alkimiya Index for PoS instruments on Oracle for a given day
     */
    function updateIndex(
        uint32 _referenceDay,
        uint256 _referenceBlock,
        uint256 _currentSupply,
        uint256 _supplyCap,
        uint256 _maxStakingDuration,
        uint256 _maxConsumptionRate,
        uint256 _minConsumptionRate,
        uint256 _mintingPeriod,
        uint256 _scale,
        bytes memory signature
    ) external returns (bool success);

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
        );
}
