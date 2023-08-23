pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import {SilicaV2_1Types} from "../../libraries/SilicaV2_1Types.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../../libraries/OrderLib.sol";

contract SilicaV2_1DeploymentTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    function testCreateSilicaV2_1() public {
        //SELLER CREATES SILICA
        uint256 sellerRewardBalance = 10000000000000000000000000;
        cheats.startPrank(sellerAddress);
        rewardToken.getFaucet(sellerRewardBalance);
        rewardToken.approve(address(testSilicaFactory), sellerRewardBalance);
        SilicaV2_1 testSilicaV2_1 = SilicaV2_1(
            testSilicaFactory.createSilicaV2_1(
                address(rewardToken),
                address(paymentToken),
                defaultResourceAmount,
                defaultLastDueDay,
                defaultUnitPrice
            )
        );
        cheats.stopPrank();
        uint32 oracleLastIndexedDay = rewardTokenOracle.getLastIndexedDay();
        assertEq(oracleLastIndexedDay, lastIndexedDay);

        uint256 collateralAmount = IERC20(address(rewardToken)).balanceOf(address(testSilicaV2_1));
        uint256 expectedCollateralAmount = ((defaultLastDueDay - lastIndexedDay - 1) *
            defaultResourceAmount *
            newAlkimiyaIndexMining.reward) / (10 * newAlkimiyaIndexMining.hashrate);
        assertEq(collateralAmount, expectedCollateralAmount);
        address silicaAddressRewardToken = testSilicaV2_1.getRewardToken();
        assertEq(address(rewardToken), silicaAddressRewardToken);
        address silicaAddressPaymentToken = testSilicaV2_1.getPaymentToken();
        assertEq(address(paymentToken), silicaAddressPaymentToken);
    }
}
