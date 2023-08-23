// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import "../../libraries/OrderLib.sol";

contract OrderLibTest is BaseTest {

  OrderLib.BuyOrder order;
  OrderLib.SellOrder sellerOrder;

  function setUp() public override {
    super.setUp();

      order = OrderLib.BuyOrder({
      commodityType: 0,
      endDay: 42,
      orderExpirationTimestamp: 20000,
      salt:0,
      resourceAmount: 600000,
      unitPrice: 4200,
      signerAddress: address(this),
      rewardToken: address(rewardToken),
      paymentToken: address(paymentToken),
      vaultAddress: address(0)
    });

    sellerOrder = OrderLib.SellOrder({
      commodityType: 0,
      endDay: 42,
      orderExpirationTimestamp: uint32(block.timestamp + 1000000),
      salt: 0,
      signerAddress: sellerAddress,
      rewardToken: address(rewardToken),
      paymentToken: address(paymentToken),
      resourceAmount: 600000,
      unitPrice: 4200,
      additionalCollateralPercent: 0
    });
  }

  function testGetBuyOrderHash() public {
    bytes32 structHash = keccak256(
      abi.encode(
        OrderLib.BUY_ORDER_TYPEHASH,
        order.commodityType,
        order.endDay,
        order.orderExpirationTimestamp,
        order.salt,
        order.resourceAmount,
        order.unitPrice,
        order.signerAddress,
        order.rewardToken,
        order.paymentToken,
        order.vaultAddress
      )
    );
    bytes32 result = OrderLib._getBuyOrderHash(order);
    assertEq(structHash, result);
  }

  function testFuzzGetBuyOrderHash(uint256 _resource, uint256 _price, uint32 _day) public {
        vm.assume(_day > 1);
        _resource = bound(_resource, 1, 1e18);
        _price = bound(_price, 1, 1e18);
        OrderLib.BuyOrder memory _order = OrderLib.BuyOrder({
            commodityType: 0,
            endDay: _day,
            orderExpirationTimestamp: uint32(block.timestamp + 1000000),
            salt: 0,
            signerAddress: sellerAddress,
            rewardToken: address(rewardToken),
            paymentToken: address(paymentToken),
            resourceAmount: _resource,
            unitPrice: _price,
            vaultAddress: address(0)
        });

        bytes32 structHash = keccak256(
          abi.encode(
            OrderLib.BUY_ORDER_TYPEHASH,
            _order.commodityType,
            _order.endDay,
            _order.orderExpirationTimestamp,
            _order.salt,
            _order.resourceAmount,
            _order.unitPrice,
            _order.signerAddress,
            _order.rewardToken,
            _order.paymentToken,
            _order.vaultAddress
          )
       );
       bytes32 result = OrderLib._getBuyOrderHash(_order);
       assertEq(structHash, result);
  }

  function testGetSellOrderHash() public {
    bytes32 structHash = keccak256(
      abi.encode(
        OrderLib.SELL_ORDER_TYPEHASH,
        sellerOrder.commodityType,
        sellerOrder.endDay,
        sellerOrder.orderExpirationTimestamp,
        sellerOrder.salt,
        sellerOrder.resourceAmount,
        sellerOrder.unitPrice,
        sellerOrder.signerAddress,
        sellerOrder.rewardToken,
        sellerOrder.paymentToken,
        sellerOrder.additionalCollateralPercent
      )
    );
    bytes32 result = OrderLib._getSellOrderHash(sellerOrder);
    assertEq(structHash, result);
  }

  function testFuzzGetSellOrderHash(uint256 _resource, uint256 _price, uint32 _day) public {
        vm.assume(_day > 1);
        _resource = bound(_resource, 1, 1e18);
        _price = bound(_price, 1, 1e18);
        OrderLib.SellOrder memory _order = OrderLib.SellOrder({
            commodityType: 0,
            endDay: _day,
            orderExpirationTimestamp: uint32(block.timestamp + 1000000),
            salt: 0,
            signerAddress: sellerAddress,
            rewardToken: address(rewardToken),
            paymentToken: address(paymentToken),
            resourceAmount: _resource,
            unitPrice: _price,
            additionalCollateralPercent: 0
        });

        bytes32 structHash = keccak256(
          abi.encode(
            OrderLib.SELL_ORDER_TYPEHASH,
            _order.commodityType,
            _order.endDay,
            _order.orderExpirationTimestamp,
            _order.salt,
            _order.resourceAmount,
            _order.unitPrice,
            _order.signerAddress,
            _order.rewardToken,
            _order.paymentToken,
            _order.additionalCollateralPercent
          )
       );
       bytes32 result = OrderLib._getSellOrderHash(_order);
       assertEq(structHash, result);
  }
}