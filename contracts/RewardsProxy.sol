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

import "./interfaces/rewardsProxy/IRewardsProxy.sol";
import "./interfaces/oracle/IOracleRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Pausable.sol";

/**
 * @title  RewardsProxy
 * @author Alkimiya Team
 * @notice Contract that sends rewards to Silica contracts
 */
contract RewardsProxy is IRewardsProxy, Pausable {

    /*///////////////////////////////////////////////////////////////
                             State Variables
    //////////////////////////////////////////////////////////////*/

    IOracleRegistry immutable oracleRegistry;

    /*///////////////////////////////////////////////////////////////
                              Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _oracleRegistry) {
        require(_oracleRegistry != address(0), "OracleRegistry address cannot be zero");
        oracleRegistry = IOracleRegistry(_oracleRegistry);
    }   

    /*///////////////////////////////////////////////////////////////
                              User Facing 
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function to stream rewards to Silica contracts
     * @param streamRequests Array of the StreamRequest struct ({
     *          silicaAddress:
     *          rToken:
     *          amount:
     * })
     */
    function streamRewards(StreamRequest[] calldata streamRequests) external whileNotPaused {
        for (uint256 i; i < streamRequests.length; ) {
            _streamReward(streamRequests[i]);
            unchecked {
                ++i;
            }
        }
        emit RewardsStreamed(streamRequests);
    }

    /*///////////////////////////////////////////////////////////////
                               Internal 
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal function to safely stream rewards to Silica contracts
    function _streamReward(StreamRequest calldata streamRequest) internal {
        SafeERC20.safeTransferFrom(IERC20(streamRequest.rToken), msg.sender, streamRequest.silicaAddress, streamRequest.amount);
    }
}
