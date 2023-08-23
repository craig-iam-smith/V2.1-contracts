// pragma solidity 0.8.19;

// import "../base/BaseTest.t.sol";
// import "../../libraries/OrderLib.sol";

// contract FillVaultBuyOrder is BaseTest {
//     event BuyOrderFilled(address silicaAddress, bytes32 orderHash, address signerAddress, address matcherAddress, uint256 purchaseAmount);

//     SwapProxy testSwapProxy;

//     uint256 hashrate = 60000000000000; //60000 gh
//     uint32 lastDueDay = 44;
//     uint256 unitPrice = 81485680; // using 1 PH/s = 0.00408836 t.wBTC | 81.48568 USDT | reservedPrice = 14667422
//     uint256 purchaseAmount = 30000000000000;

//     OrderLib.BuyOrder vaultBuyOrder;
//     bytes vaultBuyOrderSignature;
//     address silicaAddress;

//     uint256 vaultBalanceBefore;
//     uint256 sellerBalanceBefore;

//     function setUp() public override {
//         super.setUp();

//         testSwapProxy = new SwapProxy("Test");
//         testSwapProxy.setSilicaFactory(address(testSilicaFactory));

//         vaultBalanceBefore = silicaVault.totalPaymentHeld();
//         sellerBalanceBefore = rewardToken.balanceOf(sellerAddress);

//         // 1. Buyer creates order
//         vaultBuyOrder = OrderLib.BuyOrder({
//             commodityType: 0,
//             endDay: lastDueDay,
//             orderExpirationTimestamp: uint32(block.timestamp + 1000000),
//             salt: 0,
//             resourceAmount: hashrate,
//             signerAddress: address(vaultOwnerAddress),
//             vaultAddress: address(silicaVault),
//             rewardToken: address(rewardToken),
//             paymentToken: address(paymentToken),
//             unitPrice: unitPrice
//         });

//         // 1. Vault owner signs order
//         (uint8 vVaultBuyer, bytes32 rVaultBuyer, bytes32 sVaultBuyer) = vm.sign(
//             vaultOwnerPrivateKey,
//             OrderLib.getTypedDataHash(vaultBuyOrder, domainSeparator)
//         );
//         vaultBuyOrderSignature = abi.encodePacked(rVaultBuyer, sVaultBuyer, vVaultBuyer);

//         // 2. Vault does not require setting swapProxy allowance

//         // 3. Seller sets allowance
//         cheats.prank(sellerAddress);
//         rewardToken.approve(address(testSilicaFactory), 10**20);
//     }

//     function testConsumedBudgetUpdated() public {
//         cheats.prank(sellerAddress);
//         silicaAddress = swapProxy.fillBuyOrder(vaultBuyOrder, vaultBuyOrderSignature, purchaseAmount, 0);

//         require(swapProxy.buyOrderToConsumedBudget(OrderLib.getTypedDataHash(vaultBuyOrder, domainSeparator)) == purchaseAmount);
//     }

//     function testOrderCannotExceedBudget() public {
//         cheats.prank(sellerAddress);
//         silicaAddress = swapProxy.fillBuyOrder(vaultBuyOrder, vaultBuyOrderSignature, hashrate, 0);

//         cheats.prank(sellerAddress);
//         cheats.expectRevert("cannot exceed budget");
//         swapProxy.fillBuyOrder(vaultBuyOrder, vaultBuyOrderSignature, 1, 0);
//     }

//     function testVaultFundsTransferred() public {
//         cheats.prank(sellerAddress);
//         silicaAddress = swapProxy.fillBuyOrder(vaultBuyOrder, vaultBuyOrderSignature, purchaseAmount, 0);

//         uint256 reservedPrice = SilicaV2_1(silicaAddress).getReservedPrice();
//         uint256 vaultBalanceAfter = silicaVault.totalPaymentHeld();
//         require(vaultBalanceBefore - vaultBalanceAfter == reservedPrice);
//     }

//     function testVaultReceivesSilica() public {
//         cheats.prank(sellerAddress);
//         silicaAddress = swapProxy.fillBuyOrder(vaultBuyOrder, vaultBuyOrderSignature, purchaseAmount, 0);

//         require(SilicaV2_1(silicaAddress).balanceOf(address(silicaVault)) > 0);
//     }

//     function testSellerFundsTransferred() public {
//         cheats.prank(sellerAddress);
//         silicaAddress = swapProxy.fillBuyOrder(vaultBuyOrder, vaultBuyOrderSignature, purchaseAmount, 0);

//         uint256 sellerBalanceAfter = rewardToken.balanceOf(sellerAddress);

//         // We should eventually check the difference is equal to collateral
//         require(sellerBalanceBefore > sellerBalanceAfter);
//     }

//     function testVaultBuyOrderEvent() public {
//         // NOTE: ExpectedAddress is hardcoded because Silica address is returned after order fill, but we need it before the call
//         address expectedSilicaAddress = 0x8ED1BAD2D9621b617E0038931a50CBbAb08403Fb;

//         bytes32 orderHash = keccak256(abi.encodePacked("\x19\x01", swapProxy.domainSeparator(), OrderLib.getBuyOrderHash(vaultBuyOrder)));

//         cheats.expectEmit(false, false, false, true);
//         emit BuyOrderFilled(expectedSilicaAddress, orderHash, address(silicaVault), sellerAddress, purchaseAmount);

//         cheats.startPrank(sellerAddress);
//         silicaAddress = swapProxy.fillBuyOrder(vaultBuyOrder, vaultBuyOrderSignature, purchaseAmount, 0);
//         cheats.stopPrank();
//     }

//     /// Simulate signing a buy order for Vault with a non-Admin key
//     ///
//     function testOnlyAdminCanCreateValidVaultBuyOrder() public {
//         // 1. Non admin tries to create order on behalf of Vault
//         OrderLib.BuyOrder memory bogusBuyOrder = OrderLib.BuyOrder({
//             commodityType: 0,
//             endDay: lastDueDay,
//             orderExpirationTimestamp: uint32(block.timestamp + 1000000),
//             salt: 0,
//             resourceAmount: hashrate,
//             signerAddress: address(buyerAddress),
//             vaultAddress: address(silicaVault),
//             rewardToken: address(rewardToken),
//             paymentToken: address(paymentToken),
//             unitPrice: unitPrice
//         });

//         // 1. Sign order with BuyerAddress
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, OrderLib.getTypedDataHash(bogusBuyOrder, domainSeparator));
//         bytes memory bogusBuyOrderSignature = abi.encodePacked(r, s, v);

//         // 3. Seller sets allowance
//         cheats.prank(sellerAddress);
//         rewardToken.approve(address(testSilicaFactory), 10**20);

//         cheats.expectRevert("order not signed by admin");
//         cheats.prank(sellerAddress);
//         silicaAddress = swapProxy.fillBuyOrder(bogusBuyOrder, bogusBuyOrderSignature, purchaseAmount, 0);
//     }
// }
