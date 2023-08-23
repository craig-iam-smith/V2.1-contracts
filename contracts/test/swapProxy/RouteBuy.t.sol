pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {SwapProxy} from "../../SwapProxy.sol";

import "../../libraries/OrderLib.sol";

contract RouteBuy is BaseTest {
    // copy of event for event testing
    event SellOrderFilled(address silicaAddress, bytes32 orderHash, address signerAddress, address matcherAddress, uint256 purchaseAmount);

    SwapProxy testSwapProxy;

    // Parameters for Order
    uint256 hashrate = 60000000000000; //60000 gh
    uint32 lastDueDay = 44;
    uint256 unitPrice = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT | reservedPrice = 14667422

    // vars shared across test cases
    OrderLib.SellOrder sellerOrder;
    bytes sellerSignature;
    address silicaAddress;
    uint256 buyerBalanceBefore;
    uint256 sellerBalanceBefore;

    /**
     * 10**10 is the minimum buy so that it doesn't round down to 0
     * after applying Silica's decimals vs USD's decimals
     */
    uint256 purchaseAmount = 10**10;

    function setUp() public override {
        super.setUp();

        testSwapProxy = new SwapProxy("Test");
        testSwapProxy.setSilicaFactory(address(testSilicaFactory));

        cheats.prank(buyerAddress);
        paymentToken.getFaucet(10**20);
        cheats.prank(buyerAddress);
        rewardToken.getFaucet(10**20);

        cheats.prank(sellerAddress);
        rewardToken.getFaucet(10**20);

        cheats.prank(sellerAddress);
        paymentToken.getFaucet(10**20);

        buyerBalanceBefore = paymentToken.balanceOf(buyerAddress);
        sellerBalanceBefore = rewardToken.balanceOf(sellerAddress);

        // 1. Seller creates order
        sellerOrder = OrderLib.SellOrder({
            commodityType: 0,
            endDay: lastDueDay,
            orderExpirationTimestamp: uint32(block.timestamp + 1000000),
            salt: 0,
            signerAddress: sellerAddress,
            rewardToken: address(rewardToken),
            paymentToken: address(paymentToken),
            resourceAmount: hashrate,
            unitPrice: unitPrice,
            additionalCollateralPercent: 0
        });

        // 1. Seller signs order
        (uint8 vSeller, bytes32 rSeller, bytes32 sSeller) = vm.sign(
            sellerPrivateKey,
            OrderLib._getTypedDataHash(sellerOrder, domainSeparator)
        );
        sellerSignature = abi.encodePacked(rSeller, sSeller, vSeller);

        // 2. Buyer sets swapproxy allowance
        cheats.prank(buyerAddress);
        paymentToken.approve(address(swapProxy), 10**30);

        // 3. Seller sets allowance
        cheats.prank(sellerAddress);
        rewardToken.approve(address(testSilicaFactory), 10**20);

        cheats.prank(sellerAddress);
        rewardToken.approve(address(swapProxy), 10**20);

        // 4. Seller order is filled for first time
        cheats.prank(buyerAddress);
        silicaAddress = swapProxy.routeBuy(sellerOrder, sellerSignature, purchaseAmount);
    }

    // RouteBuy should not change stored address
    function testOrderMarkedAsCreated() public {
        cheats.prank(buyerAddress);
        silicaAddress = swapProxy.routeBuy(sellerOrder, sellerSignature, purchaseAmount);

        require(swapProxy.sellOrderToSilica(OrderLib._getTypedDataHash(sellerOrder, domainSeparator)) == silicaAddress);
    }

    function testFuzzOrderMarkedAsCreated(uint256 _resource, uint256 _price, uint256 _amount) public {

        _resource = bound(_resource, 1e16, 1e18);
        _price = bound(_price, 1e8, 1e18);
        _amount = bound(_amount, 10**10, 1e13);

        OrderLib.SellOrder memory _order = OrderLib.SellOrder({
            commodityType: 0,
            endDay: lastDueDay,
            orderExpirationTimestamp: uint32(block.timestamp + 1000000),
            salt: 0,
            signerAddress: sellerAddress,
            rewardToken: address(rewardToken),
            paymentToken: address(paymentToken),
            resourceAmount: _resource,
            unitPrice: _price,
            additionalCollateralPercent: 0
        });

        (uint8 vSeller, bytes32 rSeller, bytes32 sSeller) = vm.sign(
            sellerPrivateKey,
            OrderLib._getTypedDataHash(_order, domainSeparator)
        );
        sellerSignature = abi.encodePacked(rSeller, sSeller, vSeller);

        cheats.prank(buyerAddress);
        silicaAddress = swapProxy.routeBuy(_order, sellerSignature, purchaseAmount);

        require(swapProxy.sellOrderToSilica(OrderLib._getTypedDataHash(_order, domainSeparator)) == silicaAddress);
    }

    function testBuyerFundsTransferred(uint256 x) public {
        cheats.prank(buyerAddress);
        uint256 amount = x % (hashrate - 2 * purchaseAmount) + purchaseAmount;
        silicaAddress = swapProxy.routeBuy(sellerOrder, sellerSignature, amount);

        uint256 buyerBalanceAfter = paymentToken.balanceOf(buyerAddress);

        require(buyerBalanceAfter < buyerBalanceBefore);
    }

    function testBuyerReceivesSilica(uint256 x) public {
        cheats.prank(buyerAddress);
        uint256 amount = x % (hashrate - 2 * purchaseAmount) + purchaseAmount;
        silicaAddress = swapProxy.routeBuy(sellerOrder, sellerSignature, amount);
        uint256 tokensAfter = SilicaV2_1(silicaAddress).balanceOf(buyerAddress);
        uint256 tokensDiff = tokensAfter - purchaseAmount;

        require(tokensDiff >= amount * 999 / 1000);
        require(tokensDiff <= amount * 1001 / 1000);
    }

    function testSellerFundsTransferred() public {
        cheats.prank(buyerAddress);
        silicaAddress = swapProxy.routeBuy(sellerOrder, sellerSignature, purchaseAmount);

        uint256 sellerBalanceAfter = rewardToken.balanceOf(sellerAddress);

        // We should eventually check the difference is equal to collateral
        require(sellerBalanceBefore > sellerBalanceAfter);
    }
}
