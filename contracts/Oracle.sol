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

import "./interfaces/oracle/IOracle.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title  Alkimiya Oracle
 * @author Alkimiya Team
 * @notice This is the Reward Token Oracle contract
 * */
contract Oracle is AccessControl, IOracle {
    
    /*///////////////////////////////////////////////////////////////
                             State Variables
    //////////////////////////////////////////////////////////////*/

    int8 public constant VERSION = 1;
    uint32 public lastIndexedDay;

    bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");
    bytes32 public constant CALCULATOR_ROLE = keccak256("CALCULATOR_ROLE");

    mapping(uint256 day => AlkimiyaIndex index) private index;

    string public name;

    struct AlkimiyaIndex {
        uint32 referenceBlock;
        uint32 timestamp;
        uint128 hashrate;
        uint64 difficulty;
        uint256 reward;
        uint256 fees;
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

    /**
     * @notice Function to update Oracle Index
     * @dev Creates new instance of AlkimiyaIndex corresponding to _referenceDay in index mapping
     * @param _referenceDay The day to create AlkimiyaIndex entry for
     * @param _referenceBlock The block to be referenced
     * @param _hashrate The hashrate of the given day
     * @param _reward The staking reward for that day
     * @param signature The signature of the Oracle calculator
     * @return success True if index for _referenceDay has been updated
     * */
    function updateIndex(
        uint256 _referenceDay,
        uint256 _referenceBlock,
        uint256 _hashrate,
        uint256 _reward,
        uint256 _fees,
        uint256 _difficulty,
        bytes calldata signature
    ) public returns (bool success) {
        require(_hashrate <= type(uint128).max, "Hashrate cannot exceed max val");
        require(_difficulty <= type(uint64).max, "Difficulty cannot exceed max val");
        require(_referenceBlock <= type(uint32).max, "Reference block cannot exceed max val");

        require(hasRole(PUBLISHER_ROLE, msg.sender), "Update not allowed to everyone");

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(_referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty))
            )
        );

        require(hasRole(CALCULATOR_ROLE, ECDSA.recover(messageHash, signature)), "Invalid signature");

        require(index[_referenceDay].timestamp == 0, "Information cannot be updated.");

        index[_referenceDay].timestamp = uint32(block.timestamp);
        index[_referenceDay].difficulty = uint64(_difficulty);
        index[_referenceDay].referenceBlock = uint32(_referenceBlock);
        index[_referenceDay].hashrate = uint128(_hashrate);
        index[_referenceDay].reward = _reward;
        index[_referenceDay].fees = _fees;

        if (_referenceDay > lastIndexedDay) {
            lastIndexedDay = uint32(_referenceDay);
        }

        emit OracleUpdate(msg.sender, _referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty, block.timestamp);

        success = true;
    }

    /*///////////////////////////////////////////////////////////////
                                Getters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to return the AlkimiyaIndex on a given day
     * @dev Timestamp must be non-zero indicating that there is an entry to read 
     * @param _referenceDay The day whose index is to be returned 
     * */
    function get(uint256 _referenceDay)
        external
        view
        returns (
            uint256 referenceDay,
            uint256 referenceBlock,
            uint256 hashrate,
            uint256 reward,
            uint256 fees,
            uint256 difficulty,
            uint256 timestamp
        )
    {
        require(index[_referenceDay].timestamp != 0, "Date not yet indexed");

        return (
            _referenceDay,
            index[_referenceDay].referenceBlock,
            index[_referenceDay].hashrate,
            index[_referenceDay].reward,
            index[_referenceDay].fees,
            index[_referenceDay].difficulty,
            index[_referenceDay].timestamp
        );
    }

    /**
     * @notice Function to return array of oracle data between firstday and lastday (inclusive)
     * @dev The days passed in are inclusive values
     * @param _firstDay The starting day whose index is to be returned 
     * @param _lastDay The final day whose index is to be returned 
     * @return hashrateArray The hashrates for each day between _firstDay & _lastDay
     * @return rewardArray The rewards for each day between _firstDay & _lastDay
     * */
    function getInRange(uint256 _firstDay, uint256 _lastDay)
        external
        view
        returns (uint256[] memory hashrateArray, uint256[] memory rewardArray)
    {
        uint256 numElements = _lastDay + 1 - _firstDay;

        rewardArray = new uint256[](numElements);
        hashrateArray = new uint256[](numElements);

        for (uint256 i; i < numElements;) {
            AlkimiyaIndex memory indexCopy = index[_firstDay + i];
            rewardArray[i] = indexCopy.reward;
            hashrateArray[i] = indexCopy.hashrate;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Function to check if Oracle has been updated on a given day
     * @dev Days for which function calls return true have an AlkimiyaIndex entry
     * @param _referenceDay The day to check that the Oracle has an entry for
     */
    function isDayIndexed(uint256 _referenceDay) external view returns (bool) {
        return index[_referenceDay].timestamp != 0;
    }

    /**
     * @notice Function to return the latest day on which the Oracle was updated
     */
    function getLastIndexedDay() external view returns (uint32) {
        return lastIndexedDay;
    }
}
