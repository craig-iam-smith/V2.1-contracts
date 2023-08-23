pragma solidity 0.8.19;

import "../SilicaV2_1Storage.t.sol";
import {SilicaV2_1} from "../../../SilicaV2_1.sol";
import {ISilicaV2_1} from "../../../interfaces/silica/ISilicaV2_1.sol";

import {SilicaV2_1Types} from "../../../libraries/SilicaV2_1Types.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@std/Test.sol";

contract TestSetSilicaStorage is Test {
    using SilicaV2_1Storage for SilicaV2_1;

    SilicaV2_1 testSilicaV2_1;

    function setUp() public {
        testSilicaV2_1 = new SilicaV2_1();
    }

    function testSetBalance() public {
        uint256 balance = 42;
        testSilicaV2_1.setBalance(address(42), balance);
        assertEq(testSilicaV2_1.balanceOf(address(42)), balance);
    }

    function testSetTotalSupply() public {
        uint256 totalSupply = 42;
        testSilicaV2_1.setTotalSupply(totalSupply);
        assertEq(testSilicaV2_1.totalSupply(), totalSupply);
    }

    function testSetRewardToken() public {
        address rewardToken = address(42);
        testSilicaV2_1.setRewardToken(rewardToken);
        assertEq(testSilicaV2_1.rewardToken(), rewardToken);
    }

    function testSetDidSellerCollectPayout() public {
        bool didSellerCollectPayout = true;
        testSilicaV2_1.setDidSellerCollectPayout(didSellerCollectPayout);
        assertEq(testSilicaV2_1.didSellerCollectPayout(), didSellerCollectPayout);
    }

    function testSetPaymentToken() public {
        address paymentToken = address(42);
        testSilicaV2_1.setPaymentToken(paymentToken);
        assertEq(testSilicaV2_1.paymentToken(), paymentToken);
    }

    function testSetOracleRegistry() public {
        address oracleRegistry = address(42);
        testSilicaV2_1.setOracleRegistry(oracleRegistry);
        assertEq(testSilicaV2_1.oracleRegistry(), oracleRegistry);
    }

    function testSetSilicaFactory() public {
        address silicaFactory = address(42);
        testSilicaV2_1.setSilicaFactory(silicaFactory);
        assertEq(testSilicaV2_1.silicaFactory(), silicaFactory);
    }

    function testSetOwner() public {
        address owner = address(42);
        testSilicaV2_1.setOwner(owner);
        assertEq(testSilicaV2_1.owner(), owner);
    }

    function testFirstDueDay() public {
        uint32 firstDueDay = 42;
        testSilicaV2_1.setFirstDueDay(firstDueDay);
        assertEq(testSilicaV2_1.firstDueDay(), firstDueDay);
    }

    function testSetLastDueDay() public {
        uint32 lastDueDay = 42;
        testSilicaV2_1.setLastDueDay(lastDueDay);
        assertEq(testSilicaV2_1.lastDueDay(), lastDueDay);
    }

    function testSetDefaultDay() public {
        uint32 defaultDay = 42;
        testSilicaV2_1.setDefaultDay(defaultDay);
        assertEq(testSilicaV2_1.defaultDay(), defaultDay);
    }

    function testSetInitialCollateral() public {
        uint256 initialCollateral = 42;
        testSilicaV2_1.setInitialCollateral(initialCollateral);
        assertEq(testSilicaV2_1.initialCollateral(), initialCollateral);
    }

    function testSetResourceAmount() public {
        uint256 resourceAmount = 42;
        testSilicaV2_1.setResourceAmount(resourceAmount);
        assertEq(testSilicaV2_1.resourceAmount(), resourceAmount);
    }

    function testSetReservedPrice() public {
        uint256 reservedPrice = 42;
        testSilicaV2_1.setReservedPrice(reservedPrice);
        assertEq(testSilicaV2_1.reservedPrice(), reservedPrice);
    }

    function testSetRewardDelivered() public {
        uint256 rewardDelivered = 42;
        testSilicaV2_1.setReservedPrice(rewardDelivered);
        assertEq(testSilicaV2_1.reservedPrice(), rewardDelivered);
    }

    function testTotalUpFrontPayment() public {
        uint256 totalUpfrontPayment = 42;
        testSilicaV2_1.setTotalUpfrontPayment(totalUpfrontPayment);
        assertEq(testSilicaV2_1.totalUpfrontPayment(), totalUpfrontPayment);
    }

    function testSetRewardExcess() public {
        uint256 rewardExcess = 42;
        testSilicaV2_1.setRewardExcess(rewardExcess);
        assertEq(testSilicaV2_1.rewardExcess(), rewardExcess);
    }
}
