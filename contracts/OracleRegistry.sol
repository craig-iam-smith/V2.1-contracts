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

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/oracle/IOracleRegistry.sol";

contract OracleRegistry is Ownable, IOracleRegistry {

    /*///////////////////////////////////////////////////////////////
                             State Variables
    //////////////////////////////////////////////////////////////*/

    mapping(address token => mapping(uint256 commodityType => address oracle)) public oracleRegistry;

    /*///////////////////////////////////////////////////////////////
                                 Getters
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to return the list of Oracle addresses
    /// @param _token The address of the payment token
    /// @param _oracleType The commodity type of the oracle
    /// @return address: The address of the oracle contract
    function getOracleAddress(address _token, uint256 _oracleType) public view returns (address) {
        return oracleRegistry[_token][_oracleType];
    }

    /*///////////////////////////////////////////////////////////////
                                 Setters
    //////////////////////////////////////////////////////////////*/

    /// @notice Set Oracle Addresses
    /// @param _token The address of the payment token
    /// @param _oracleType The commodity type of the oracle
    /// @param _oracleAddr The address of the oracle contract
    function setOracleAddress(
        address _token,
        uint256 _oracleType,
        address _oracleAddr
    ) public onlyOwner {
        require(_token != address(0), "Invalid Token Address");
        require(_token.code.length > 0, "Invalid Token Contract");
        require(_oracleAddr != address(0), "Invalid Token Address");

        emit OracleRegistered(_token, _oracleType, _oracleAddr);
        oracleRegistry[_token][_oracleType] = _oracleAddr;
    }
}
