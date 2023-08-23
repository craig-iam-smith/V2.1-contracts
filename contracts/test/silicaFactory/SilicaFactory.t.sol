pragma solidity 0.8.19;

import "@std/console.sol";
import "../base/BaseTest.t.sol";
import {TestHelpers} from "../helpers/TestHelpers.t.sol";
import "../../interfaces/silicaFactory/ISilicaFactory.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";

contract SilicaFactoryTest is BaseTest {

    /// @notice The event emited when a new Silica contract is created.
    event NewSilicaContract(address newContractAddress, ISilicaV2_1.InitializeData initializeData, uint16 commodityType);

    event Initialized(uint8 version);

    uint256 hashrate = 1000000000000000; //1 PH/s
    uint32 lastDueDay = 44;
    uint256 unitPrice = 81; //81 USDT / PH ==> 0.000081 USDT / GH

    function setUp() public override {
        super.setUp();
    }

    function testCreateSilica() public {

        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        SilicaV2_1 testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate, lastDueDay, unitPrice)
        );
        cheats.stopPrank();

        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Open));
        uint256 expectedReservedPrice = TestHelpers.getReservedPrice(address(testSilicaV2_1), unitPrice);
        uint256 expectedInitialCollateral = TestHelpers.getInitialCollateral(address(testSilicaV2_1), address(rewardTokenOracle));

        assertEq(testSilicaV2_1.reservedPrice(), expectedReservedPrice);
        assertEq(testSilicaV2_1.initialCollateral(), expectedInitialCollateral);
        assertEq(rewardToken.balanceOf(address(testSilicaV2_1)), expectedInitialCollateral);
        assertEq(testSilicaV2_1.balanceOf(buyerAddress), 0);
    }

    function testCreateSilicaEventEmit() public {

        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        ISilicaV2_1.InitializeData memory initializeData;
        initializeData = ISilicaV2_1.InitializeData({
            rewardTokenAddress: address(rewardToken),
            paymentTokenAddress: address(paymentToken),
            oracleRegistry: address(oracleRegistry),
            sellerAddress: sellerAddress,
            dayOfDeployment: 0,
            lastDueDay:lastDueDay,
            unitPrice: unitPrice,
            resourceAmount: hashrate,
            collateralAmount: 1000000000000000
        });

        vm.expectEmit(true,false,false,true);
        emit Initialized(1);
        // NOTE: ExpectedAddress is hardcoded because Silica address is returned after order fill, but we need it before the call
        emit NewSilicaContract(0x8ED1BAD2D9621b617E0038931a50CBbAb08403Fb, initializeData, 0);
        testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), hashrate, lastDueDay, unitPrice);
        cheats.stopPrank();
    }

    function testFuzzCreateSilica(uint256 _resourceAmount, uint256 _price) public {
        _resourceAmount = bound(_resourceAmount, 1e13, 1e18);
        _price = bound(_price, 100, 1e18);
        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        SilicaV2_1 testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(address(rewardToken), address(paymentToken), _resourceAmount, lastDueDay, _price)
        );
        cheats.stopPrank();

        assertEq(uint256(testSilicaV2_1.getStatus()), uint256(SilicaV2_1Types.Status.Open));
        uint256 expectedReservedPrice = TestHelpers.getReservedPrice(address(testSilicaV2_1), _price);
        uint256 expectedInitialCollateral = TestHelpers.getInitialCollateral(address(testSilicaV2_1), address(rewardTokenOracle));

        assertEq(testSilicaV2_1.reservedPrice(), expectedReservedPrice);
        assertEq(testSilicaV2_1.initialCollateral(), expectedInitialCollateral);
        assertEq(rewardToken.balanceOf(address(testSilicaV2_1)), expectedInitialCollateral);
        assertEq(testSilicaV2_1.balanceOf(buyerAddress), 0);
    }
}