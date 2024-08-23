// pragma solidity 0.8.19;

// import "../base/BaseTest.t.sol";
// import "../../libraries/OrderLib.sol";

// contract FillSellOrderAsVault is BaseTest {
//     // copy of event for event testing
//     event SellOrderFilled(address silicaAddress, bytes32 orderHash, address signerAddress, address matcherAddress, uint256 purchaseAmount);

//     SwapProxy testSwapProxy;

//     uint256 hashrate = 60000000000000; //60000 gh
//     uint32 lastDueDay = 44;
//     uint256 unitPrice = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT | reservedPrice = 14667422
//     uint256 purchaseAmount = 1000000;

//     OrderLib.SellOrder sellerOrder;
//     bytes sellerSignature;
//     address silicaAddress;

//     uint256 vaultBalanceBefore;
//     uint256 sellerBalanceBefore;

//     function setUp() public override {
//         super.setUp();

//         testSwapProxy = new SwapProxy("Test");
//         testSwapProxy.setSilicaFactory(address(testSilicaFactory));

//         vaultBalanceBefore = silicaVault.totalPaymentHeld();
//         sellerBalanceBefore = rewardToken.balanceOf(sellerAddress);

//         // 1. Seller creates order
//         sellerOrder = OrderLib.SellOrder({
//             commodityType: 0,
//             endDay: lastDueDay,
//             orderExpirationTimestamp: uint32(block.timestamp + 1000000),
//             salt: 0,
//             signerAddress: sellerAddress,
//             rewardToken: address(rewardToken),
//             paymentToken: address(paymentToken),
//             resourceAmount: hashrate,
//             unitPrice: unitPrice,
//             additionalCollateralPercent: 0
//         });

//         // 1. Seller signs order
//         (uint8 vSeller, bytes32 rSeller, bytes32 sSeller) = vm.sign(
//             sellerPrivateKey,
//             OrderLib.getTypedDataHash(sellerOrder, domainSeparator)
//         );
//         sellerSignature = abi.encodePacked(rSeller, sSeller, vSeller);

//         // 2. Buyer sets swapproxy allowance
//         cheats.prank(buyerAddress);
//         paymentToken.approve(address(swapProxy), 10**20);

//         // 3. Seller sets allowance
//         cheats.prank(sellerAddress);
//         rewardToken.approve(address(testSilicaFactory), 10**20);

//         cheats.prank(sellerAddress);
//         rewardToken.approve(address(swapProxy), 10**20);
//     }

//     function testOrderMarkedAsCreated() public {
//         cheats.prank(vaultOwnerAddress);
//         silicaAddress = swapProxy.fillSellOrderAsVault(sellerOrder, sellerSignature, purchaseAmount, address(silicaVault));

//         require(swapProxy.sellOrderToSilica(OrderLib.getTypedDataHash(sellerOrder, domainSeparator)) == silicaAddress);
//     }

//     function testOrderCannotBeCreatedTwice() public {
//         cheats.prank(vaultOwnerAddress);
//         silicaAddress = swapProxy.fillSellOrderAsVault(sellerOrder, sellerSignature, purchaseAmount, address(silicaVault));

//         cheats.prank(vaultOwnerAddress);
//         cheats.expectRevert("order already filled");
//         swapProxy.fillSellOrderAsVault(sellerOrder, sellerSignature, 10**6, address(silicaVault));
//     }

//     function testVaultFundsTransferred() public {
//         cheats.prank(vaultOwnerAddress);
//         silicaAddress = swapProxy.fillSellOrderAsVault(sellerOrder, sellerSignature, purchaseAmount, address(silicaVault));

//         uint256 vaultBalanceAfter = silicaVault.totalPaymentHeld();
//         require(vaultBalanceBefore - vaultBalanceAfter == purchaseAmount);
//     }

//     function testBuyerReceivesSilica() public {
//         cheats.prank(vaultOwnerAddress);
//         silicaAddress = swapProxy.fillSellOrderAsVault(sellerOrder, sellerSignature, purchaseAmount, address(silicaVault));

//         require(SilicaV2_1(silicaAddress).balanceOf(address(silicaVault)) > 0);
//     }

//     function testSellerFundsTransferred() public {
//         cheats.prank(vaultOwnerAddress);
//         silicaAddress = swapProxy.fillSellOrderAsVault(sellerOrder, sellerSignature, purchaseAmount, address(silicaVault));

//         uint256 sellerBalanceAfter = rewardToken.balanceOf(sellerAddress);

//         // We should eventually check the difference is equal to collateral
//         require(sellerBalanceBefore > sellerBalanceAfter);
//     }

//     function testOnlyAdminCanFillSellOrderAsVault() public {
//         cheats.expectRevert("only admin can fill order as vault");

//         cheats.prank(sellerAddress);
//         silicaAddress = swapProxy.fillSellOrderAsVault(sellerOrder, sellerSignature, purchaseAmount, address(silicaVault));
//     }

//     function testVaultFillSellOrderEvent() public {
//         // NOTE: ExpectedAddress is hardcoded because Silica address is returned after order fill, but we need it before the call
//         address expectedSilicaAddress = 0x8ED1BAD2D9621b617E0038931a50CBbAb08403Fb;

//         bytes32 orderHash = keccak256(abi.encodePacked("\x19\x01", swapProxy.domainSeparator(), OrderLib.getSellOrderHash(sellerOrder)));

//         cheats.expectEmit(false, false, false, true);
//         emit SellOrderFilled(expectedSilicaAddress, orderHash, sellerAddress, address(silicaVault), purchaseAmount);

//         cheats.startPrank(vaultOwnerAddress);
//         silicaAddress = swapProxy.fillSellOrderAsVault(sellerOrder, sellerSignature, purchaseAmount, address(silicaVault));
//         cheats.stopPrank();
//     }
// }