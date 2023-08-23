pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import "../../libraries/OrderLib.sol";

contract CancelBuyOrder is BaseTest {
    SwapProxy testSwapProxy;

    OrderLib.BuyOrder buyerOrder;
    bytes buyerSignature;

    function setUp() public override {
        super.setUp();

        testSwapProxy = new SwapProxy("Test");
        testSwapProxy.setSilicaFactory(address(testSilicaFactory));

        cheats.prank(buyerAddress);
        paymentToken.getFaucet(10**10);

        cheats.prank(sellerAddress);
        rewardToken.getFaucet(10**20);

        // 1. Buyer creates order
        buyerOrder = OrderLib.BuyOrder({
            commodityType: 0,
            endDay: 19999,
            orderExpirationTimestamp: uint32(block.timestamp + 1000000),
            salt: 0,
            signerAddress: buyerAddress,
            rewardToken: address(rewardToken),
            paymentToken: address(paymentToken),
            resourceAmount: 100000000,
            unitPrice: 1000000000000,
            vaultAddress: address(0)
        });

        // 1. Buyer signs order
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(buyerPrivateKey, OrderLib._getTypedDataHash(buyerOrder, domainSeparator));
        buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // 2. Buyer sets swapproxy allowance
        cheats.prank(buyerAddress);
        paymentToken.approve(address(swapProxy), 10**10);

        // 3. Buyer cancels order
        cheats.prank(buyerAddress);
        swapProxy.cancelBuyOrder(buyerOrder, buyerSignature);
    }

    function testOrderMarkedAsCancelled() public {
        assertTrue(swapProxy.buyOrdersCancelled(OrderLib._getTypedDataHash(buyerOrder, domainSeparator)));
    }

    function testCancelledOrderCannotBeFulfilled() public {
        cheats.expectRevert("This order was cancelled");
        cheats.prank(sellerAddress);
        swapProxy.fillBuyOrder(buyerOrder, buyerSignature, 10**8, 0);
    }
}

contract CancelSellOrder is BaseTest {
    SwapProxy testSwapProxy;

    OrderLib.SellOrder sellerOrder;
    bytes sellerSignature;

    function setUp() public override {
        super.setUp();

        testSwapProxy = new SwapProxy("Test");
        testSwapProxy.setSilicaFactory(address(testSilicaFactory));

        cheats.prank(buyerAddress);
        paymentToken.getFaucet(10**10);

        cheats.prank(sellerAddress);
        rewardToken.getFaucet(10**20);

        // 1. Seller creates order
        sellerOrder = OrderLib.SellOrder({
            commodityType: 0,
            endDay: 19999,
            orderExpirationTimestamp: uint32(block.timestamp + 1000000),
            salt: 0,
            signerAddress: sellerAddress,
            rewardToken: address(rewardToken),
            paymentToken: address(paymentToken),
            resourceAmount: 100000000,
            unitPrice: 1000000000000,
            additionalCollateralPercent: 0
        });

        // 1. Seller signs order
        (uint8 vSeller, bytes32 rSeller, bytes32 sSeller) = vm.sign(
            sellerPrivateKey,
            OrderLib._getTypedDataHash(sellerOrder, domainSeparator)
        );
        sellerSignature = abi.encodePacked(rSeller, sSeller, vSeller);

        // 2. Seller sets swapproxy allowance
        cheats.prank(sellerAddress);
        paymentToken.approve(address(swapProxy), 10**10);

        // 3. Seller cancels order
        cheats.prank(sellerAddress);
        swapProxy.cancelSellOrder(sellerOrder, sellerSignature);
    }

    function testOrderMarkedAsCancelled() public {
        assertTrue(swapProxy.sellOrdersCancelled(OrderLib._getTypedDataHash(sellerOrder, domainSeparator)));
    }

    function testCancelledOrderCannotBeFulfilled() public {
        cheats.expectRevert("This order was cancelled");
        cheats.prank(sellerAddress);
        swapProxy.fillSellOrder(sellerOrder, sellerSignature, 1);
    }
}
