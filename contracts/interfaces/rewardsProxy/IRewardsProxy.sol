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

/**
 * @title  Reward Proxy Interface
 * @author Alkimiya Team
 * */
interface IRewardsProxy {
    
    /// @notice Event emitted when rewards are streamed to a Silica
    event RewardsStreamed(StreamRequest[] streamRequests);

    struct StreamRequest {
        address silicaAddress;
        address rToken;
        uint256 amount;
    }

    struct RewardDue {
        address silicaAddress;
        address rToken;
        uint256 amount;
    }

    /// @notice Function to stream rewards to Silica contracts
    function streamRewards(StreamRequest[] calldata streamRequests) external;
}
