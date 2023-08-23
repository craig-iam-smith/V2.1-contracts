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

import "./interfaces/oracle/oracleEthStaking/IOracleEthStaking.sol";
import {AbstractSilicaV2_1} from "./AbstractSilicaV2_1.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/oracle/IOracleRegistry.sol";
import "./libraries/math/RewardMath.sol";

contract SilicaEthStaking is AbstractSilicaV2_1 {

    /*///////////////////////////////////////////////////////////////
                               Constants
    //////////////////////////////////////////////////////////////*/

    uint256 public constant COMMODITY_TYPE = 2;

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/
    
    constructor() ERC20("Silica", "SLC") {}

    /*///////////////////////////////////////////////////////////////
                                Getters
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to return the last day Silica was synced with Oracle
    /// @return uint32: The last day the Silica was synced with the Oracle
    function _getLastIndexedDay() internal override view returns (uint32) {
        IOracleEthStaking oracleEthStaking = IOracleEthStaking(
            IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE)
        );
        uint32 lastIndexedDayMem = oracleEthStaking.getLastIndexedDay();
        require(lastIndexedDayMem != 0, "Invalid State");

        return lastIndexedDayMem;
    }

    /// @notice Function to return the amount of rewards due by the seller to the contract on day inputed
    /// @param _day The day on which to query the reward
    /// @return uint256: The reward due on the input day
    function _getRewardDueOnDay(uint256 _day) internal view override returns (uint256) {
        IOracleEthStaking oracleEthStaking = IOracleEthStaking(
            IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE)
        );
        (, uint256 baseRewardPerIncrementPerDay, , , , , ) = oracleEthStaking.get(_day);

        return RewardMath._getEthStakingRewardDue(totalSupply(), baseRewardPerIncrementPerDay, decimals());
    }

    /// @notice Function to return total rewards due between _firstday (inclusive) and _lastday (inclusive)
    /// @dev    This function is to be overridden by derived Silica contracts
    /// @param _firstDay The start day to query from
    /// @param _lastDay The end day to query until 
    function _getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view override returns (uint256[] memory) {
        IOracleEthStaking oracleEthStaking = IOracleEthStaking(
            IOracleRegistry(oracleRegistry).getOracleAddress(address(rewardToken), COMMODITY_TYPE)
        );
        uint256[] memory baseRewardPerIncrementPerDayArray = oracleEthStaking.getInRange(_firstDay, _lastDay);

        uint256[] memory rewardDueArray = new uint256[](baseRewardPerIncrementPerDayArray.length);

        uint8 decimalsMem = decimals();
        uint256 totalSupplyCopy = totalSupply();
        for (uint256 i; i < baseRewardPerIncrementPerDayArray.length; ) {
            rewardDueArray[i] = RewardMath._getEthStakingRewardDue(totalSupplyCopy, baseRewardPerIncrementPerDayArray[i], decimalsMem);
            unchecked {
                ++i;
            }
        }

        return rewardDueArray;
    }

    /// @notice Returns the commodity type the seller is selling with this contract
    /// @return The commodity type the seller is selling with this contract
    function getCommodityType() external pure override returns (uint256) {
        return COMMODITY_TYPE;
    }

    /// @notice Returns decimals of the contract
    /// @return uint8: Decimals
    function getDecimals() external pure override returns (uint8) {
        return decimals();
    }
}