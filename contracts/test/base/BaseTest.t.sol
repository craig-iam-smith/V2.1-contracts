pragma solidity >=0.8.0;

import "../../../lib/forge-std/src/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../test/tokens/USDT.sol";
import "../../test/tokens/WBTC.sol";
import "../../test/tokens/WETH.sol";
import "../../test/CheatCodes.t.sol";

import {OracleRegistry} from "../../OracleRegistry.sol";
import {Oracle} from "../../Oracle.sol";
import {OracleEthStaking} from "../../OracleEthStaking.sol";
import {OracleRegistryStorage} from "../../test/storage/OracleRegistryStorage.t.sol";
import {OracleStorage} from "../../test/storage/OracleStorage.t.sol";
import {OracleEthStakingStorage} from "../../test/storage/OracleEthStakingStorage.t.sol";
import {SilicaV2_1} from "../../SilicaV2_1.sol";
import {SilicaEthStaking} from "../../SilicaEthStaking.sol";
import {SilicaFactory} from "../../SilicaFactory.sol";
import {SwapProxy} from "../../SwapProxy.sol";
//import {SilicaVault} from "@alkimiya/v1-silicavault-core/contracts/SilicaVault.sol";
import "../../../lib/forge-std/src/console.sol";

abstract contract BaseTest is Test {
    using OracleStorage for Oracle;
    using OracleEthStakingStorage for OracleEthStaking;
    using OracleRegistryStorage for OracleRegistry;

    // SILICA //
    SilicaV2_1 MasterSilicaV2_1;
    SilicaEthStaking MasterSilicaEthStaking;
    SilicaFactory testSilicaFactory;

    // VAULT //
    //SilcaVault silicaVault;

    // TOKENS //
    USDT paymentToken;
    WrappedBTC rewardToken;
    WrappedETH stakingRewardToken;

    function setUpTokens() internal {
        paymentToken = new USDT();
        rewardToken = new WrappedBTC();
        stakingRewardToken = new WrappedETH();
    }

    // ORACLES //
    OracleRegistry oracleRegistry;
    Oracle rewardTokenOracle;
    OracleEthStaking oracleEthStaking;
    uint256 internal oraclePublisherPrivateKey;
    address internal oraclePublisherAddress;
    uint256 internal oracleCalculatorPrivateKey;
    address internal oracleCalculatorAddress;

    uint32 lastIndexedDay = 40;
    CheatCodes constant cheats = CheatCodes(VM_ADDRESS);

    function setUpOracles() internal {
        oraclePublisherPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        oracleCalculatorPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

        oraclePublisherAddress = vm.addr(oraclePublisherPrivateKey);
        oracleCalculatorAddress = vm.addr(oracleCalculatorPrivateKey);

        oracleRegistry = new OracleRegistry();

        rewardTokenOracle = new Oracle("WBTC 1");
        rewardTokenOracle.grantRole(keccak256("PUBLISHER_ROLE"), oraclePublisherAddress);
        rewardTokenOracle.grantRole(keccak256("CALCULATOR_ROLE"), oracleCalculatorAddress);
        
        oracleEthStaking = new OracleEthStaking("WETH 1");
        oracleEthStaking.grantRole(keccak256("PUBLISHER_ROLE"), oraclePublisherAddress);
        oracleEthStaking.grantRole(keccak256("CALCULATOR_ROLE"), oracleCalculatorAddress);

        updateOracle(address(rewardTokenOracle), lastIndexedDay);
        oracleRegistry.setOracle(address(rewardToken), 0, address(rewardTokenOracle));
        oracleRegistry.setOracle(address(stakingRewardToken), 2, address(oracleEthStaking));
    }

    // SWAP PROXY
    bytes32 domainSeparator;
    SwapProxy swapProxy;

    function setSwapProxySilicaFactory() internal {
        swapProxy.setSilicaFactory(address(testSilicaFactory));
        domainSeparator = swapProxy.domainSeparator();
    }

    uint256 defaultResourceAmount;
    uint32 defaultLastDueDay;
    uint32 defaultFirstDueDay;
    uint256 defaultUnitPrice;
    uint256 defaultStakingAmount;
    uint256 defaultStakingBaseReward;
    uint256 defaultStakingUnitPrice;
    uint256 defaultStakingReservedPrice;
    uint256 defaultStakingInitialCollateral;

    function setContractData() internal {
        defaultResourceAmount = 6000000000000000;
        defaultFirstDueDay = 40;
        defaultLastDueDay = 44;
        defaultUnitPrice = 10000000;
        defaultStakingAmount = 10**20; //100 ETH
        defaultStakingBaseReward = 185000000000000; // 0.000185 ETH
        defaultStakingUnitPrice = (defaultStakingBaseReward * 1250000000) / 10**18; // using 1250 USDT/ETH
        defaultStakingReservedPrice = (defaultStakingAmount * defaultStakingUnitPrice) / 10**MasterSilicaEthStaking.decimals();
        defaultStakingInitialCollateral =
            ((defaultLastDueDay - defaultFirstDueDay + 1) * defaultStakingAmount * defaultStakingBaseReward) /
            (10**(MasterSilicaEthStaking.decimals() + 1));
    }

    /// SELLERS + BUYERS ///
    uint256 internal sellerPrivateKey;
    uint256 internal buyerPrivateKey;
    uint256 internal vaultOwnerPrivateKey;

    address internal sellerAddress;
    address internal buyerAddress;
    address internal vaultOwnerAddress;

    uint256 sellerRewardBalance;
    uint256 buyerPaymentBalance;

    function setBuyerAndSeller() internal {
        sellerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        buyerPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        vaultOwnerPrivateKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

        sellerAddress = vm.addr(sellerPrivateKey);
        buyerAddress = vm.addr(buyerPrivateKey);
        vaultOwnerAddress = vm.addr(vaultOwnerPrivateKey);

        cheats.startPrank(sellerAddress);
        sellerRewardBalance = 10000000000000000000000000;
        rewardToken.getFaucet(sellerRewardBalance);
        stakingRewardToken.getFaucet(defaultStakingInitialCollateral);
        cheats.stopPrank();

        cheats.startPrank(buyerAddress);
        buyerPaymentBalance = 18000000000000000000;
        paymentToken.getFaucet(buyerPaymentBalance);
        cheats.stopPrank();
    }

    function setUp() public virtual {
        setUpTokens();
        setUpOracles();
        MasterSilicaV2_1 = new SilicaV2_1();
        MasterSilicaEthStaking = new SilicaEthStaking();
        swapProxy = new SwapProxy("SwapProxy");
        testSilicaFactory = new SilicaFactory(
            address(MasterSilicaV2_1),
            address(MasterSilicaEthStaking),
            address(oracleRegistry),
            address(swapProxy)
        );
        setContractData();
        setDefaultOracleEntries();
        setBuyerAndSeller();
        setSwapProxySilicaFactory();
        //setUpVault();
    }

    /// HELPERS ///
    Oracle.AlkimiyaIndex newAlkimiyaIndexMining;
    OracleEthStaking.AlkimiyaEthStakingIndex defaultOracleStakingEntry;

    function setDefaultOracleEntries() internal {
        newAlkimiyaIndexMining.referenceBlock = uint32(751767);
        newAlkimiyaIndexMining.timestamp = uint32(1);
        newAlkimiyaIndexMining.hashrate = uint128(221270464457411230000);
        newAlkimiyaIndexMining.reward = uint256(97967223332);
        newAlkimiyaIndexMining.fees = uint256(1092223332);

        defaultOracleStakingEntry.baseRewardPerIncrementPerDay = uint256(185000000000000);
        defaultOracleStakingEntry.timestamp = uint256((defaultFirstDueDay - 2) * 24 * 60 * 60);
    }

    function updateOracle(address _oracleAddress, uint32 _dateToIndex) public {
        newAlkimiyaIndexMining.referenceBlock = uint32(751767);
        newAlkimiyaIndexMining.timestamp = uint32(1);
        newAlkimiyaIndexMining.hashrate = uint128(221270464457411230000);
        newAlkimiyaIndexMining.reward = uint256(97967223332);
        newAlkimiyaIndexMining.fees = uint256(1092223332);

        Oracle oracle = Oracle(_oracleAddress);

        oracle.setLastIndexedDay(_dateToIndex);
        oracle.setIndexAtDay(_dateToIndex, newAlkimiyaIndexMining);
    }

    function updateOracleEthStaking(
        address _oracleAddress,
        uint32 _dateToIndex,
        OracleEthStaking.AlkimiyaEthStakingIndex memory newStakingEntry
    ) public {
        OracleEthStaking oracleEthStakingToUpdate = OracleEthStaking(_oracleAddress);
        oracleEthStakingToUpdate.setLastIndexedDay(_dateToIndex);
        oracleEthStakingToUpdate.setIndexAtDay(_dateToIndex, newStakingEntry);
    }

    // function setUpVault() internal {
    //     cheats.startPrank(vaultOwnerAddress);
    //     silicaVault = new SilicaVault(
    //         address(paymentToken),
    //         address(rewardToken),
    //         address(oracleRegistry),
    //         address(swapProxy),
    //         address(0) /*swaprouter - remove */
    //     );

    //     paymentToken.getFaucet(10**18);
    //     paymentToken.transfer(address(silicaVault), 10**18);

    //     silicaVault.startNextRound(300000); // start very long epoch for convenience

    //     cheats.stopPrank();
    // }
}
