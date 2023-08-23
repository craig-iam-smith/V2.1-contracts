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

import "../base/BaseTest.t.sol";
import "../../libraries/OrderLib.sol";
import {RewardsProxy} from "../../RewardsProxy.sol";
import {ISilicaV2_1} from "../../interfaces/silica/ISilicaV2_1.sol";
import {IRewardsProxy} from "../../interfaces/rewardsProxy/IRewardsProxy.sol";

contract PauseTest is BaseTest {

  bytes buyerSignature;
  SwapProxy testSwapProxy;
  OrderLib.BuyOrder buyerOrder;
  ISilicaV2_1 testSilicaV2_1_1;
  RewardsProxy testRewardsProxy;
  
  function setUp() public override {
    super.setUp();

    testSwapProxy = new SwapProxy("Test");
    testRewardsProxy = new RewardsProxy(address(oracleRegistry));

    buyerOrder = OrderLib.BuyOrder({
            commodityType: 0,
            endDay: 1000,
            orderExpirationTimestamp: uint32(block.timestamp + 1000000),
            salt: 0,
            signerAddress: buyerAddress,
            rewardToken: address(rewardToken),
            paymentToken: address(paymentToken),
            resourceAmount: 60000,
            unitPrice: 2000,
            vaultAddress: address(0)
    });

    (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(buyerPrivateKey, OrderLib._getTypedDataHash(buyerOrder, domainSeparator));
    buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

    rewardToken.approve(address(testSilicaFactory), 1e18);
    testSilicaV2_1_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), 80000000000000, 55, 81485680)
    );
  }

  function testPauseUpdatesStateFactory() public {
    assertEq(testSilicaFactory.paused(), false);
    testSilicaFactory.pause();
    assertEq(testSilicaFactory.paused(), true);
  }

  function testPauseModifierFactory() public {
    testSilicaFactory.pause();
    vm.expectRevert("Contract is currently paused");
    testSilicaFactory.createSilicaV2_1(
                address(stakingRewardToken),
                address(paymentToken),
                defaultStakingAmount,
                defaultLastDueDay,
                defaultStakingUnitPrice
    );
  }

  function testActivateUpdatesStateFactory() public {
    assertEq(testSilicaFactory.paused(), false);
    testSilicaFactory.pause();
    assertEq(testSilicaFactory.paused(), true);
    testSilicaFactory.activate();
    assertEq(testSilicaFactory.paused(), false);
  }

  function testPauseUpdatesStateSwapProxy() public {
    assertEq(testSwapProxy.paused(), false);
    testSwapProxy.pause();
    assertEq(testSwapProxy.paused(), true);
  }

  function testPauseModifierSwapProxy() public {
    testSwapProxy.pause();
    vm.expectRevert("Contract is currently paused");
    testSwapProxy.fillBuyOrder(
      buyerOrder,
      buyerSignature,
      1000,
      0
    );
  }

  function testActivateUpdatesStateSwapProxy() public {
    testSwapProxy.pause();
    assertEq(testSwapProxy.paused(), true);
    testSwapProxy.activate();
    assertEq(testSwapProxy.paused(), false);
  }

  function testPauseUpdatesStateRewProxy() public {
    assertEq(testRewardsProxy.paused(), false);
    testRewardsProxy.pause();
    assertEq(testRewardsProxy.paused(), true);
  }

  function testPausedModifierRewProxy() public {
    IRewardsProxy.StreamRequest[] memory streamRequests = new IRewardsProxy.StreamRequest[](1);
    streamRequests[0].silicaAddress = address(testSilicaV2_1_1);
    streamRequests[0].rToken = address(rewardToken);
    streamRequests[0].amount = testSilicaV2_1_1.getRewardDueNextOracleUpdate();

    testRewardsProxy.pause();
    vm.expectRevert("Contract is currently paused");
    testRewardsProxy.streamRewards(streamRequests);
  }

  function testActivateUpdatesStateRewProxy() public {
    testRewardsProxy.pause();
    assertEq(testRewardsProxy.paused(), true);
    testRewardsProxy.activate();
    assertEq(testRewardsProxy.paused(), false);
  }

}