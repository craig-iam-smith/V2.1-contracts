pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import "../../libraries/OrderLib.sol";

contract FillBuyOrder is BaseTest {
    // copy of emitted event, to test
    event BuyOrderFilled(address silicaAddress, bytes32 orderHash, address signerAddress, address matcherAddress, uint256 purchaseAmount);

    SwapProxy testSwapProxy;

    // Parameters for Order
    uint256 hashrate = 60000000000000; //60000 gh
    uint32 lastDueDay = 44;
    uint256 unitPrice = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT | reservedPrice = 14667422
    uint256 purchaseAmount = 30000000000000;

    // vars shared across test cases
    OrderLib.BuyOrder buyerOrder;
    bytes buyerSignature;
    address silicaAddress;
    uint256 buyerBalanceBefore;
    uint256 sellerBalanceBefore;

    function setUp() public override {
        super.setUp();

        testSwapProxy = new SwapProxy("Test");
        testSwapProxy.setSilicaFactory(address(testSilicaFactory));

        buyerBalanceBefore = paymentToken.balanceOf(buyerAddress);
        sellerBalanceBefore = rewardToken.balanceOf(sellerAddress);

        buyerOrder = OrderLib.BuyOrder({
            commodityType: 0,
            endDay: lastDueDay,
            orderExpirationTimestamp: uint32(block.timestamp + 1000000),
            salt: 0,
            signerAddress: buyerAddress,
            rewardToken: address(rewardToken),
            paymentToken: address(paymentToken),
            resourceAmount: hashrate,
            unitPrice: unitPrice,
            vaultAddress: address(0)
        });

        // 1. Buyer signs order
        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(buyerPrivateKey, OrderLib._getTypedDataHash(buyerOrder, domainSeparator));
        buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);

        // 2. Buyer sets swapproxy allowance
        cheats.prank(buyerAddress);
        paymentToken.approve(address(swapProxy), 1e18);

        // 3. Seller sets allowance
        cheats.prank(sellerAddress);
        rewardToken.approve(address(testSilicaFactory), 10**20);
    }

    function testOrderMarkedAsCreated() public {
        cheats.prank(sellerAddress);
        silicaAddress = swapProxy.fillBuyOrder(buyerOrder, buyerSignature, purchaseAmount, 0);

        require(swapProxy.buyOrderToConsumedBudget(OrderLib._getTypedDataHash(buyerOrder, domainSeparator)) == purchaseAmount);
    }

    function testFuzzBuyOrderMarkedAsCreated(uint256 _amount, uint256 _resource, uint256 _price) public {
        _resource = bound(_resource, 1e14, 1e18);
        _price = bound(_price, 1000, 1e18);
        _amount = bound(_amount, 1e12, 1e14);
        OrderLib.BuyOrder memory _order = OrderLib.BuyOrder({
            commodityType: 0,
            endDay: lastDueDay,
            orderExpirationTimestamp: uint32(block.timestamp + 1000000),
            salt: 0,
            signerAddress: buyerAddress,
            rewardToken: address(rewardToken),
            paymentToken: address(paymentToken),
            resourceAmount: _resource,
            unitPrice: _price,
            vaultAddress: address(0)
        });

        (uint8 vBuyer, bytes32 rBuyer, bytes32 sBuyer) = vm.sign(buyerPrivateKey, OrderLib._getTypedDataHash(_order, domainSeparator));
        buyerSignature = abi.encodePacked(rBuyer, sBuyer, vBuyer);
        cheats.prank(sellerAddress);
        silicaAddress = swapProxy.fillBuyOrder(_order, buyerSignature, _amount, 0);

        require(swapProxy.buyOrderToConsumedBudget(OrderLib._getTypedDataHash(_order, domainSeparator)) == _amount);
    }

    function testOrderCannotExceedBudget() public {
        cheats.prank(sellerAddress);
        silicaAddress = swapProxy.fillBuyOrder(buyerOrder, buyerSignature, hashrate, 0); // Buy out the full contract

        cheats.prank(sellerAddress);
        cheats.expectRevert("cannot exceed budget");
        swapProxy.fillBuyOrder(buyerOrder, buyerSignature, 1, 0);
    }

    function testBuyerFundsTransferred() public {
        cheats.prank(sellerAddress);
        silicaAddress = swapProxy.fillBuyOrder(buyerOrder, buyerSignature, purchaseAmount, 0);

        SilicaV2_1 silicaContract = SilicaV2_1(silicaAddress);
        uint256 reservedPrice = silicaContract.getReservedPrice();

        uint256 buyerBalanceAfter = paymentToken.balanceOf(buyerAddress);
        require(buyerBalanceBefore - buyerBalanceAfter == reservedPrice, "Buyer should transfer reservedPrice of contract");
    }

    function testBuyerReceivesSilica() public {
        cheats.prank(sellerAddress);
        silicaAddress = swapProxy.fillBuyOrder(buyerOrder, buyerSignature, purchaseAmount, 0);

        require(SilicaV2_1(silicaAddress).balanceOf(buyerAddress) == purchaseAmount, "Buyer should receive Silica equal to purchaseAmount");
    }

    function testSellerFundsTransferred() public {
        cheats.prank(sellerAddress);
        silicaAddress = swapProxy.fillBuyOrder(buyerOrder, buyerSignature, purchaseAmount, 0);

        uint256 sellerBalanceAfter = rewardToken.balanceOf(sellerAddress);

        // We should eventually check the difference is equal to collateral
        require(sellerBalanceBefore > sellerBalanceAfter);
    }

    function testFuzzAdditionalCollateral(uint256 x) public {
        cheats.prank(sellerAddress);
        try swapProxy.fillBuyOrder(buyerOrder, buyerSignature, purchaseAmount, x) {
          uint256 sellerBalanceAfter = rewardToken.balanceOf(sellerAddress);
          require(sellerBalanceBefore > sellerBalanceAfter);
          uint256 rewardTransferred = sellerBalanceBefore - sellerBalanceAfter;
          require(rewardTransferred > 3983 * (10 + x) / 10);
          require(rewardTransferred < 3985 * (10 + x) / 10);
        } catch {
          require(x >= 1000);
        }
    }
/* @!!! quick removal of the following test case
    function testBuyOrderEvent() public {
        // NOTE: ExpectedAddress is hardcoded because Silica address is returned after order fill, but we need it before the call
        address expectedSilicaAddress = 0xCC7A29dc69577d218eC6EB8f57eB6738ddB5f800;

        bytes32 orderHash = keccak256(abi.encodePacked("\x19\x01", swapProxy.domainSeparator(), OrderLib._getBuyOrderHash(buyerOrder)));

        cheats.expectEmit(false, false, false, true);
        emit BuyOrderFilled(expectedSilicaAddress, orderHash, buyerAddress, sellerAddress, purchaseAmount);

        cheats.startPrank(sellerAddress);
        silicaAddress = swapProxy.fillBuyOrder(buyerOrder, buyerSignature, purchaseAmount, 0);
        cheats.stopPrank();
    }
*/
}
