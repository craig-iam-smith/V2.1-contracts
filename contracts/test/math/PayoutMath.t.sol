// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@std/Test.sol";
import "../../libraries/math/PayoutMath.sol";

contract PayoutMathTest is Test {

  function testGetHaircut() public {
    uint256 numDepositsCompleted = 200; 
    uint256 contractNumberOfDeposits = 1000;
    uint256 contractNumberOfDepositsCubed = uint256(contractNumberOfDeposits)**3;
    uint256 multiplier = ((numDepositsCompleted**3) * PayoutMath.FIXED_POINT_SCALE_VALUE) / (contractNumberOfDepositsCubed); // 8e11
    uint256 result = (PayoutMath.HAIRCUT_BASE_PCT * multiplier) / (100 * PayoutMath.FIXED_POINT_BASE); // 640000
    // Expected = (FIXED_POINT_BASE * 100) - result
    uint256 expected = 99360000;
    uint256 actual = PayoutMath._getHaircut(
      numDepositsCompleted,
      contractNumberOfDeposits
    );
    assertEq(expected, actual);
  }

  function testFuzzGetHaircut(uint256 _numDepositsCompleted, uint256 _contractNumberOfDeposits) public {
    _numDepositsCompleted = bound(_numDepositsCompleted, 1, 1e3);
    _contractNumberOfDeposits = bound(_contractNumberOfDeposits, 1000, 1e18);
    uint256 _contractNumberOfDepositsCubed = uint256(_contractNumberOfDeposits)**3;
    uint256 multiplier = ((_numDepositsCompleted**3) * PayoutMath.FIXED_POINT_SCALE_VALUE) / (_contractNumberOfDepositsCubed); // 8e11
    uint256 result = (PayoutMath.HAIRCUT_BASE_PCT * multiplier) / (100 * PayoutMath.FIXED_POINT_BASE); // 640000
    // Expected = (FIXED_POINT_BASE * 100) - result
    uint256 expected = (PayoutMath.FIXED_POINT_BASE * 100) - result;
    uint256 actual = PayoutMath._getHaircut(
      _numDepositsCompleted,
      _contractNumberOfDeposits);
    assertEq(expected, actual);
  }
  
  function testGetRewardTokenPayoutToBuyerOnDefault() public {
    uint256 buyerTokenBalance = 2000;
    uint256 totalRewardDelivered = 1000;
    uint256 totalSilicaMinted = 50; 
    // Exepcted = (_buyerTokenBalance * _totalRewardDelivered) / _totalSilicaMinted
    uint256 expected = 40000;
    uint256 actual = PayoutMath._getRewardTokenPayoutToBuyerOnDefault(
      buyerTokenBalance,
      totalRewardDelivered,
      totalSilicaMinted);
    assertEq(expected, actual);
  }

  function testFuzzGetRewardTokenPayoutToBuyerOnDefault(
    uint256 _buyerTokenBalance,
    uint256 _totalRewardDelivered,
    uint256 _totalSilicaMinted) public {
    _buyerTokenBalance = bound(_buyerTokenBalance, 1, 1e18);
    _totalRewardDelivered = bound(_totalRewardDelivered, 1, 1e18);
    _totalSilicaMinted = bound(_totalSilicaMinted, 1, 1e18); 
    // Exepcted = (_buyerTokenBalance * _totalRewardDelivered) / _totalSilicaMinted
    uint256 expected = (_buyerTokenBalance * _totalRewardDelivered) / _totalSilicaMinted;
    uint256 actual = PayoutMath._getRewardTokenPayoutToBuyerOnDefault(
      _buyerTokenBalance,
      _totalRewardDelivered,
      _totalSilicaMinted);
    assertEq(expected, actual);
  }

  function testGetPaymentTokenPayoutToBuyerOnDefault() public {
    uint256 buyerTokenBalance = 200000000000;
    uint256 totalSilicaMinted = 1;
    uint256 totalUpfrontPayment = 10000000000;
    uint256 haircut = 50000000;
    // Expected = (_buyerTokenBalance * _totalUpfrontPayment * _haircut) / (_totalSilicaMinted * SCALING_FACTOR)
    uint256 expected = 10;
    uint256 actual = PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
      buyerTokenBalance,
      totalSilicaMinted,
      totalUpfrontPayment,
      haircut
    );
    assertEq(expected, actual);
  }

  function testFuzzGetPaymentTokenPayoutToBuyerOnDefault(
    uint256 _buyerTokenBalance,
    uint256 _totalUpfrontPayment,
    uint256 _totalSilicaMinted
    ) public {
    _buyerTokenBalance = bound(_buyerTokenBalance, 1, 1e18);
    _totalSilicaMinted = bound(_totalSilicaMinted, 1, 1e18);
    _totalUpfrontPayment = bound(_totalUpfrontPayment, 1, 1e18);
    uint256 haircut = 50000000;
    // Expected = (_buyerTokenBalance * _totalUpfrontPayment * _haircut) / (_totalSilicaMinted * SCALING_FACTOR)
    uint256 expected = (_buyerTokenBalance * _totalUpfrontPayment * haircut) / (_totalSilicaMinted * 1e8);
    uint256 actual = PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
      _buyerTokenBalance,
      _totalUpfrontPayment,
      _totalSilicaMinted,
      haircut
    );
    assertEq(expected, actual);
  }

  function testGetRewardPayoutToSellerOnDefault() public {
    uint256 totalUpfrontPayment = 1000;
    uint256 hairCutPct = 10000;
    uint256 haircutPctRemainder = 99990000;
    // Expected = (haircutPctRemainder * _totalUpfrontPayment) / 100000000
    uint256 expected = 999;
    uint256 actual = PayoutMath._getRewardPayoutToSellerOnDefault(
      totalUpfrontPayment,
      hairCutPct
    );
    assertEq(expected, actual);
  }

  function testFuzzGetRewardPayoutToSellerOnDefault(uint256 _totalUpfrontPayment, uint256 _hairCutPct) public {
    _totalUpfrontPayment = bound(_totalUpfrontPayment, 1, 1e18);
    _hairCutPct = bound(_hairCutPct, 1, 1e8);
    // Expected = (haircutPctRemainder * _totalUpfrontPayment) / 100000000
     
    uint256 haircutPctRemainder = uint256(100000000) - _hairCutPct;
    uint256 expected = (haircutPctRemainder * _totalUpfrontPayment) / 100000000;
    uint256 actual = PayoutMath._getRewardPayoutToSellerOnDefault(
      _totalUpfrontPayment,
      _hairCutPct
    );
    assertEq(expected, actual);
  }

  function testCalculateReservedPrice() public {
    uint256 unitPrice = 60000;
    uint256 resourceAmount = 4000;
    uint256 numDeposits = 20;
    uint256 decimals = 6;
    // Expected = (unitPrice * resourceAmount * numDeposits) / (10**decimals)
    uint256 expected = 4800;
    uint256 actual = PayoutMath._calculateReservedPrice(
      unitPrice,
      resourceAmount,
      numDeposits,
      decimals
    );
    assertEq(expected, actual);
  }

  function testFuzzCalculateReservedPrice(
    uint256 _unitPrice,
    uint256 _resourceAmount,
    uint256 _numDeposits,
    uint256 _decimals) public {
    _unitPrice = bound(_unitPrice, 1, 1e18);
    _resourceAmount = bound(_resourceAmount, 1, 1e18);
    _numDeposits = bound(_numDeposits, 1, 1e18);
    _decimals = bound(_decimals, 1, 18);
    // Expected = (unitPrice * resourceAmount * numDeposits) / (10**decimals)
    uint256 expected = (_unitPrice * _resourceAmount * _numDeposits) / (10**_decimals);
    uint256 actual = PayoutMath._calculateReservedPrice(
      _unitPrice,
      _resourceAmount,
      _numDeposits,
      _decimals
    );
    assertEq(expected, actual);
  }

  function testGetBuyerRewardPayout() public {
    uint256 rewardDelivered = 2000;
    uint256 buyerBalance = 1000;
    uint256 resourceAmount = 4000;
    // Expected = (rewardDelivered * buyerBalance) / resourceAmount
    uint256 expected = 500;
    uint256 actual = PayoutMath._getBuyerRewardPayout(
      rewardDelivered,
      buyerBalance,
      resourceAmount
    );
    assertEq(expected, actual);
  }

  function testFuzzGetBuyerRewardPayout(
    uint256 _rewardDelivered,
    uint256 _buyerBalance,
    uint256 _resourceAmount
  ) public {
    _rewardDelivered = bound(_rewardDelivered, 1, 1e18);
    _buyerBalance = bound(_buyerBalance, 1, 1e18);
    _resourceAmount = bound(_resourceAmount, 1, 1e18);
    // Expected = (rewardDelivered * buyerBalance) / resourceAmount
    uint256 expected = (_rewardDelivered * _buyerBalance) / _resourceAmount;
    uint256 actual = PayoutMath._getBuyerRewardPayout(
      _rewardDelivered,
      _buyerBalance,
      _resourceAmount
    );
    assertEq(expected, actual);
  }

}