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
import "../../../lib/forge-std/src/console.sol";

contract Pause is BaseTest {

  SwapProxy testSwapProxy;

  function setUp() public override {
    super.setUp();
    testSwapProxy = new SwapProxy("Test");
    
  }

  function testPauseUpdatesState() public {
    assertEq(testSilicaFactory.paused(), false);
    testSilicaFactory.pause();
    assertEq(testSilicaFactory.paused(), true);
  }

  function testPauseModifier() public {
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

  function testActivateUpdatesState() public {
    assertEq(testSilicaFactory.paused(), false);
    testSilicaFactory.pause();
    assertEq(testSilicaFactory.paused(), true);
    testSilicaFactory.activate();
    assertEq(testSilicaFactory.paused(), false);
  }
}