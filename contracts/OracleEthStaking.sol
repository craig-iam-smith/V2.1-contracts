// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/oracle/oracleEthStaking/IOracleEthStaking.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title  Alkimiya Oracle
 * @author Alkimiya Team
 * @notice This is the ETH Staking Oracle contract
 */
contract OracleEthStaking is AccessControl, IOracleEthStaking {
    
    /*///////////////////////////////////////////////////////////////
                             State Variables
    //////////////////////////////////////////////////////////////*/

    int8 public constant VERSION = 1;
    uint32 public lastIndexedDay;

    bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");
    bytes32 public constant CALCULATOR_ROLE = keccak256("CALCULATOR_ROLE");

    mapping(uint256 day => AlkimiyaEthStakingIndex index) private index;

    string public name;

    struct AlkimiyaEthStakingIndex {
        uint256 baseRewardPerIncrementPerDay;
        uint256 burnFee; // Total burn fee from all blocks of the day
        uint256 priorityFee; // Total priority fee from all blocks of the day
        uint256 burnFeeNormalized; // Sum(burnFee_per_epoch/total_staked_eth_per_epoch)
        uint256 priorityFeeNormalized; // Sum(priorityFee_per_epoch/total_staked_eth_per_epoch)
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
                                 Setters
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to update Oracle Index
    /// @param _referenceDay The day to query 
    /// @param _baseRewardPerIncrementPerDay The base reward
    /// @param _burnFee Total burn fee from all blocks of the day
    /// @param _priorityFee Total priority fee from all blocks of the day
    /// @param _burnFeeNormalized Sum(burnFee_per_epoch/total_staked_eth_per_epoch)
    /// @param _priorityFeeNormalized Sum(priorityFee_per_epoch/total_staked_eth_per_epoch)
    /// @param signature Signature of oracle
    /// @return bool: Successful update of index has occured
    function updateIndex(
        uint256 _referenceDay,
        uint256 _baseRewardPerIncrementPerDay,
        uint256 _burnFee,
        uint256 _priorityFee,
        uint256 _burnFeeNormalized,
        uint256 _priorityFeeNormalized,
        bytes calldata signature
    ) public returns (bool) {
        require(hasRole(PUBLISHER_ROLE, msg.sender), "Update not allowed to everyone");

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        _referenceDay,
                        _baseRewardPerIncrementPerDay,
                        _burnFee,
                        _priorityFee,
                        _burnFeeNormalized,
                        _priorityFeeNormalized
                    )
                )
            )
        );
        require(hasRole(CALCULATOR_ROLE, ECDSA.recover(messageHash, signature)), "Invalid signature");

        require(index[_referenceDay].timestamp == 0, "Information cannot be updated.");

        index[_referenceDay].baseRewardPerIncrementPerDay = _baseRewardPerIncrementPerDay;
        index[_referenceDay].burnFee = _burnFee;
        index[_referenceDay].priorityFee = _priorityFee;
        index[_referenceDay].burnFeeNormalized = _burnFeeNormalized;
        index[_referenceDay].priorityFeeNormalized = _priorityFeeNormalized;
        index[_referenceDay].timestamp = block.timestamp;

        if (_referenceDay > lastIndexedDay) {
            lastIndexedDay = uint32(_referenceDay);
        }

        emit OracleUpdate(
            msg.sender,
            _referenceDay,
            block.timestamp,
            _baseRewardPerIncrementPerDay,
            _burnFee,
            _priorityFee,
            _burnFeeNormalized,
            _priorityFeeNormalized
        );

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                                 Getters
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to return Oracle index on given day
    /// @param _referenceDay The day to query the index for
    /// @return referenceDay The day the index was written on
    /// @return baseRewardPerIncrementPerDay The base reward
    /// @return burnFee Total burn fee from all blocks of the day
    /// @return priorityFee Total priority fee from all blocks of the day
    /// @return burnFeeNormalized Sum(burnFee_per_epoch/total_staked_eth_per_epoch)
    /// @return priorityFeeNormalized Sum(priorityFee_per_epoch/total_staked_eth_per_epoch)
    function get(uint256 _referenceDay)
        external
        view
        returns (
            uint256 referenceDay,
            uint256 baseRewardPerIncrementPerDay,
            uint256 burnFee,
            uint256 priorityFee,
            uint256 burnFeeNormalized,
            uint256 priorityFeeNormalized,
            uint256 timestamp
        )
    {
        require(index[_referenceDay].timestamp != 0, "Date not yet indexed");

        return (
            _referenceDay,
            index[_referenceDay].baseRewardPerIncrementPerDay,
            index[_referenceDay].burnFee,
            index[_referenceDay].priorityFee,
            index[_referenceDay].burnFeeNormalized,
            index[_referenceDay].priorityFeeNormalized,
            index[_referenceDay].timestamp
        );
    }

    /// @notice Function to return array of oracle data between firstday and lastday (inclusive)
    /// @param _firstDay The starting day whose index is to be returned 
    /// @param _lastDay The final day whose index is to be returned
    /// @return baseRewardPerIncrementPerDayArray an array of base reward values
    function getInRange(uint256 _firstDay, uint256 _lastDay)
        external
        view
        returns (uint256[] memory baseRewardPerIncrementPerDayArray)
    {
        uint256 numElements = _lastDay + 1 - _firstDay;

        baseRewardPerIncrementPerDayArray = new uint256[](numElements);

        for (uint256 i; i < numElements; ) {
            AlkimiyaEthStakingIndex memory indexCopy = index[_firstDay + i];
            require(indexCopy.timestamp != 0, "Missing data in range");
            baseRewardPerIncrementPerDayArray[i] = indexCopy.baseRewardPerIncrementPerDay;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Function to check if Oracle is updated on a given day
    /// @dev Days for which function calls return true have an AlkimiyaIndex entry
    /// @param _referenceDay The day to check that the Oracle has an entry for
    /// @return bool: Was the day indexed
    function isDayIndexed(uint256 _referenceDay) external view override returns (bool) {
        return index[_referenceDay].timestamp != 0;
    }

    /// @notice Function to return the latest day on which the Oracle was updated
    function getLastIndexedDay() external view override returns (uint32) {
        return lastIndexedDay;
    }
}
