pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import "../../libraries/OrderLib.sol";
import "../../libraries/SilicaV2_1Types.sol";
import {SwapProxy} from "../../SwapProxy.sol";


contract FillSellOrder is BaseTest {
    // copy of event for event testing
    event SellOrderFilled(address silicaAddress, bytes32 orderHash, address signerAddress, address matcherAddress, uint256 purchaseAmount);

    SwapProxy testSwapProxy;

    // Parameters for Order
    uint256 hashrate = 6 * 10**13; //60000 gh
    uint32 lastDueDay = 50; // duration: 42-50
    uint256 unitPrice = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT | reservedPrice = 14667422

    // vars shared across test cases
    OrderLib.SellOrder sellerOrder;
    bytes sellerSignature;
    address silicaAddress;
    uint256 buyerBalanceBefore;
    uint256 sellerBalanceBefore;

    /**
     * 10**12 is the minimum buy so that it doesn't round down to 0
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
        paymentToken.approve(address(swapProxy), 10**20);

        // 3. Seller sets allowance
        cheats.prank(sellerAddress);
        rewardToken.approve(address(testSilicaFactory), 10**20);

        cheats.prank(sellerAddress);
        rewardToken.approve(address(swapProxy), 10**20);
    }

    function testOrderMarkedAsCreated() public {
        cheats.prank(buyerAddress);
        silicaAddress = swapProxy.fillSellOrder(sellerOrder, sellerSignature, purchaseAmount);

        require(swapProxy.sellOrderToSilica(OrderLib._getTypedDataHash(sellerOrder, domainSeparator)) == silicaAddress);
    }

    function testFuzzSellOrderMarkedAsCreated(uint256 _resource, uint256 _price, uint256 _amount) public {
        _resource = bound(_resource, 1e13, 1e18);
        _price = bound(_price, 1e5, 1e18);
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
        silicaAddress = swapProxy.fillSellOrder(_order, sellerSignature, _amount);

        require(swapProxy.sellOrderToSilica(OrderLib._getTypedDataHash(_order, domainSeparator)) == silicaAddress);
    }

    function testOrderCannotBeCreatedTwice() public {
        cheats.prank(buyerAddress);
        silicaAddress = swapProxy.fillSellOrder(sellerOrder, sellerSignature, purchaseAmount);

        cheats.prank(buyerAddress);
        cheats.expectRevert("order already filled");
        swapProxy.fillSellOrder(sellerOrder, sellerSignature, 10**6);
    }

    function testCanBuyUpToResourceAmount(uint256 x) public {
        cheats.prank(buyerAddress);

        uint256 amount = x % (hashrate - purchaseAmount) + purchaseAmount;
        silicaAddress = swapProxy.fillSellOrder(sellerOrder, sellerSignature, amount);

        uint256 buyerBalanceAfter = paymentToken.balanceOf(buyerAddress);
        require(buyerBalanceAfter < buyerBalanceBefore);
    }

    function testCantBuyMoreThanResourceAmount(uint256 x) public {
        cheats.prank(buyerAddress);
        uint256 amount = (hashrate * 100001 / 100000) + (x % 2**128);
        vm.expectRevert();
        swapProxy.fillSellOrder(sellerOrder, sellerSignature, amount);
    }

    function testBuyerReceivesSilica(uint256 x) public {
        cheats.prank(buyerAddress);
        uint256 amount = x % (hashrate - purchaseAmount) + purchaseAmount;
        silicaAddress = swapProxy.fillSellOrder(sellerOrder, sellerSignature, amount);

        uint256 tokensReceived = SilicaV2_1(silicaAddress).balanceOf(buyerAddress);

        require(tokensReceived >= amount * 999 / 1000);
        require(tokensReceived <= amount * 1001 / 1000);
    }

    function testSellerFundsTransferred(uint256 x) public {
        cheats.prank(buyerAddress);
        uint256 amount = x % (hashrate - purchaseAmount) + purchaseAmount;
        silicaAddress = swapProxy.fillSellOrder(sellerOrder, sellerSignature, amount);

        uint256 sellerBalanceAfter = rewardToken.balanceOf(sellerAddress);

        // We should eventually check the difference is equal to collateral
        require(sellerBalanceBefore > sellerBalanceAfter);
    }
/* @!!! quick removal to alleviate stack too deep error on coverage
    function testAdditionalCollateralPercent(uint256 x, uint256 y) public {
        sellerOrder.additionalCollateralPercent = y;
        (uint8 vSeller, bytes32 rSeller, bytes32 sSeller) = vm.sign(
            sellerPrivateKey,
            OrderLib._getTypedDataHash(sellerOrder, domainSeparator)
        );
        sellerSignature = abi.encodePacked(rSeller, sSeller, vSeller);

        cheats.prank(buyerAddress);
        uint256 amount = x % (hashrate - purchaseAmount) + purchaseAmount;
        try swapProxy.fillSellOrder(sellerOrder, sellerSignature, amount) returns (address silicaAddress) {
          SilicaV2_1 silica = SilicaV2_1(silicaAddress);
          uint32 duration = uint32(silica.lastDueDay() + 1 - silica.firstDueDay());
          uint32 firstDueDayMem = silica.firstDueDay();
          uint256 sellerBalanceAfter = rewardToken.balanceOf(sellerAddress);
          require(sellerBalanceBefore > sellerBalanceAfter);

          uint256 rewardTokenTransferred = sellerBalanceBefore - sellerBalanceAfter;
          require(rewardTokenTransferred > (10 + y) * 265 * duration);
          require(rewardTokenTransferred < (10 + y) * 266 * duration);

          // should default iff initial collateral < 100%
          bool defaulted = false;
          uint32 i = 0;
          for (i = 0; i < duration; i++) {
            if (SilicaV2_1(silicaAddress).getStatus() == SilicaV2_1Types.Status.Defaulted) {
              defaulted = true;
            }
            updateOracle(address(rewardTokenOracle), firstDueDayMem + i);
          }
          (uint a, uint b) = SilicaV2_1(silicaAddress).getDaysAndRewardFulfilled();

          if (y >= 90) {
            require(!defaulted);
          // 30% buffer for rounding imprecision:
          } else if (amount >= hashrate * (y + 10) * 13 / 1000) {
            require(defaulted);
          }
        } catch {
          require(y >= 1000);
        }
    }
    

    function testAdditionalCollateralPercentEx1() public {
      testAdditionalCollateralPercent(hashrate - purchaseAmount - 1, 200);
    }

    function testAdditionalCollateralPercentEx2() public {
      testAdditionalCollateralPercent(hashrate - purchaseAmount - 1, 91);
    }

    function testAdditionalCollateralPercentEx3() public {
      testAdditionalCollateralPercent(hashrate - purchaseAmount - 1, 90);
    }

    function testAdditionalCollateralPercentEx4() public {
      testAdditionalCollateralPercent(hashrate - purchaseAmount - 1, 89);
    }

    function testAdditionalCollateralPercentEx5() public {
      testAdditionalCollateralPercent(hashrate - purchaseAmount - 1, 0);
    }

    function testAdditionalCollateralPercentEx6() public {
      testAdditionalCollateralPercent(hashrate - purchaseAmount - 1, 49);
    }

    function testAdditionalCollateralPercentEx7() public {
      testAdditionalCollateralPercent(purchaseAmount, 200);
    }

    function testAdditionalCollateralPercentEx8() public {
      testAdditionalCollateralPercent(purchaseAmount, 91);
    }

    function testAdditionalCollateralPercentEx9() public {
      testAdditionalCollateralPercent(purchaseAmount, 90);
    }

    function testAdditionalCollateralPercentEx10() public {
      testAdditionalCollateralPercent(purchaseAmount, 89);
    }

    function testAdditionalCollateralPercentEx11() public {
      testAdditionalCollateralPercent(purchaseAmount, 0);
    }

    function testAdditionalCollateralPercentEx12() public {
      testAdditionalCollateralPercent(purchaseAmount, 49);
    }

    function testSellOrderEvent() public {
        // NOTE: ExpectedAddress is hardcoded because Silica address is returned after order fill, but we need it before the call
        address expectedSilicaAddress = 0xCC7A29dc69577d218eC6EB8f57eB6738ddB5f800;

        bytes32 orderHash = keccak256(abi.encodePacked("\x19\x01", swapProxy.domainSeparator(), OrderLib._getSellOrderHash(sellerOrder)));

        cheats.expectEmit(false, false, false, true);
        emit SellOrderFilled(expectedSilicaAddress, orderHash, sellerAddress, buyerAddress, purchaseAmount);

        cheats.prank(buyerAddress);
        silicaAddress = swapProxy.fillSellOrder(sellerOrder, sellerSignature, purchaseAmount);
    }
    */
}
