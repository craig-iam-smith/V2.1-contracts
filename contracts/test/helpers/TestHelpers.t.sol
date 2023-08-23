pragma solidity 0.8.19;

import {SilicaV2_1} from "../../SilicaV2_1.sol";
import {SilicaEthStaking} from "../../SilicaEthStaking.sol";
import {Oracle} from "../../Oracle.sol";
import {OracleEthStaking} from "../../OracleEthStaking.sol";

import "../../../lib/forge-std/src/console.sol";

library TestHelpers {
    //This function assumes that the oracle data is the same for every day
    function getTotalRewardDueWhenFinished(
        address silicaAddress,
        address oracleAddress,
        uint256 dayForOracleData
    ) public view returns (uint256 totalRewardDue) {
        SilicaV2_1 silicaV2_1 = SilicaV2_1(silicaAddress);
        Oracle oracle = Oracle(oracleAddress);

        uint256 hashrate = silicaV2_1.totalSupply();
        (, , uint256 networkHashrate, uint256 networkReward, , , ) = oracle.get(dayForOracleData);
        uint256 oneDayRewardDue = (hashrate * networkReward) / networkHashrate;
        uint256 numOfDaysDue = silicaV2_1.lastDueDay() + 1 - silicaV2_1.firstDueDay();

        totalRewardDue = oneDayRewardDue * numOfDaysDue;
    }

    function getTotalRewardDueWhenFinishedEthStaking(
        address silicaAddress,
        address oracleAddress,
        uint256 dayForOracleData
    ) public view returns (uint256 totalRewardDue) {
        SilicaEthStaking silicaEthStaking = SilicaEthStaking(silicaAddress);
        OracleEthStaking oracleEthStaking = OracleEthStaking(oracleAddress);

        uint256 stakedAmount = silicaEthStaking.totalSupply();
        (, uint256 baseRewardPerIncrementPerDay, , , , , ) = oracleEthStaking.get(dayForOracleData);
        uint256 numOfDaysDue = silicaEthStaking.lastDueDay() + 1 - silicaEthStaking.firstDueDay();

        uint256 oneDayRewardDue = (baseRewardPerIncrementPerDay * stakedAmount) / (10**silicaEthStaking.decimals());
        totalRewardDue = numOfDaysDue * oneDayRewardDue;
    }

    function getContractBalanceOnDay(address silicaAddress, address oracleAddress) public view returns (uint256 contractBalance) {
        contractBalance = getContractBalanceOnGivenDay(silicaAddress, oracleAddress, Oracle(oracleAddress).getLastIndexedDay());
    }

    function getContractBalanceOnGivenDay(
        address silicaAddress,
        address oracleAddress,
        uint32 givenDay
    ) public view returns (uint256 contractBalance) {
        SilicaV2_1 silicaV2_1 = SilicaV2_1(silicaAddress);
        Oracle oracle = Oracle(oracleAddress);

        uint256 firstDueDay = silicaV2_1.firstDueDay();
        if (givenDay < firstDueDay) {
            return (silicaV2_1.initialCollateral());
        }
        uint256 lastDayContractOwesReward = givenDay - 1 <= silicaV2_1.lastDueDay() ? givenDay - 1 : silicaV2_1.lastDueDay();
        uint256 numDaysOwed = lastDayContractOwesReward + 1 - firstDueDay;
        uint256 totalDue;

        for (uint256 i = 0; i < numDaysOwed; i++) {
            uint256 curDay = firstDueDay + i;
            (, , uint256 networkHashrate, uint256 networkReward, , , ) = oracle.get(curDay);
            uint256 collateralLocked = getCollateralLocked(silicaAddress, oracleAddress, curDay, firstDueDay - 2);
            totalDue += (silicaV2_1.totalSupply() * networkReward) / networkHashrate;

            if (contractBalance < totalDue + collateralLocked) {
                contractBalance = totalDue + collateralLocked;
            }
        }

        if (silicaV2_1.initialCollateral() > contractBalance) {
            contractBalance = silicaV2_1.initialCollateral();
        }
    }

    function getExpectedContractBalanceOnAGivenDayEthStaking(
        address silicaAddress,
        address oracleAddress,
        uint32 givenDay
    ) public view returns (uint256 contractBalance) {
        SilicaEthStaking silicaEthStaking = SilicaEthStaking(silicaAddress);
        OracleEthStaking oracleEthStaking = OracleEthStaking(oracleAddress);
        uint32 firstDueDay = silicaEthStaking.firstDueDay();
        uint32 lastDueDay = silicaEthStaking.lastDueDay();
        uint256 initialCollateral = silicaEthStaking.initialCollateral();

        uint256 stakedAmount = silicaEthStaking.totalSupply();

        uint256 totalDueOnDay;
        for (uint256 day = silicaEthStaking.firstDueDay(); day <= givenDay; day++) {
            (, uint256 baseRewardPerIncrementPerDay, , , , , ) = oracleEthStaking.get(day);
            uint256 dayReward = (baseRewardPerIncrementPerDay * stakedAmount) / (10**silicaEthStaking.decimals());

            totalDueOnDay += dayReward;
        }

        uint256 initialCollateralAfterRelease = (initialCollateral * stakedAmount) / silicaEthStaking.resourceAmount();

        uint256 numDeposits = lastDueDay + 1 - firstDueDay;
        uint256 initCollateralReleaseDay = numDeposits % 4 > 0 ? firstDueDay + 1 + (numDeposits / 4) : firstDueDay + (numDeposits / 4);
        uint256 finalCollateralReleaseDay = numDeposits % 2 > 0 ? firstDueDay + 1 + (numDeposits / 2) : firstDueDay + (numDeposits / 2);

        uint256 collateralLocked = getCollateralLockedOnDayFromCollateralLockedAfterRelease(
            givenDay,
            initCollateralReleaseDay,
            finalCollateralReleaseDay,
            initialCollateralAfterRelease
        );

        contractBalance = totalDueOnDay + collateralLocked;

        if (initialCollateral > contractBalance) {
            contractBalance = initialCollateral;
        }
    }

    function getCollateralLockedOnDayFromCollateralLockedAfterRelease(
        uint256 day,
        uint256 initCollateralReleaseDay,
        uint256 finalCollateralReleaseDay,
        uint256 initialCollateralAfterRelease
    ) internal pure returns (uint256) {
        if (day >= finalCollateralReleaseDay) {
            return (0);
        }
        if (day >= initCollateralReleaseDay) {
            return ((initialCollateralAfterRelease * 3) / 4);
        }
        return (initialCollateralAfterRelease);
    }

    function getTotalRewardDeliveredWhenDefault(
        address silicaAddress,
        address oracleAddress,
        uint256 dayOfDefault
    ) public view returns (uint256 TotalRewardDeliveredWhenDefault) {
        SilicaV2_1 silicaV2_1 = SilicaV2_1(silicaAddress);
        Oracle oracle = Oracle(oracleAddress);

        uint256 hashrate = silicaV2_1.totalSupply();

        uint256 totalRewardDelivered;
        for (uint256 day = silicaV2_1.firstDueDay(); day < dayOfDefault; day++) {
            (, , uint256 networkHashrate, uint256 networkReward, , , ) = oracle.get(day);
            uint256 dayReward = (hashrate * networkReward) / networkHashrate;
            totalRewardDelivered += dayReward;
        }
        uint256 collateralLocked = getCollateralLocked(silicaAddress, oracleAddress, dayOfDefault, silicaV2_1.firstDueDay() - 2);

        return (totalRewardDelivered + collateralLocked);
    }

    function getTotalRewardDeliveredWhenDefaultEthStaking(
        address silicaAddress,
        address oracleAddress,
        uint256 dayOfDefault,
        uint256 collateralLocked
    ) public view returns (uint256 TotalRewardDeliveredWhenDefault) {
        SilicaEthStaking silicaEthStaking = SilicaEthStaking(silicaAddress);
        OracleEthStaking oracleEthStaking = OracleEthStaking(oracleAddress);

        uint256 stakedAmount = silicaEthStaking.totalSupply();

        uint256 totalRewardDelivered;
        for (uint256 day = silicaEthStaking.firstDueDay(); day < dayOfDefault; day++) {
            (, uint256 baseRewardPerIncrementPerDay, , , , , ) = oracleEthStaking.get(day);
            uint256 dayReward = (baseRewardPerIncrementPerDay * stakedAmount) / (10**silicaEthStaking.decimals());

            totalRewardDelivered += dayReward;
        }

        return (totalRewardDelivered + collateralLocked);
    }

    function getCollateralLocked(
        address silicaAddress,
        address oracleAddress,
        uint256 day,
        uint256 dayForOracleData
    ) public view returns (uint256 collateralLocked) {
        SilicaV2_1 silicaV2_1 = SilicaV2_1(silicaAddress);
        Oracle oracle = Oracle(oracleAddress);

        (, , uint256 networkHashrate, uint256 networkReward, , , ) = oracle.get(dayForOracleData);

        uint256 numDeposits = silicaV2_1.lastDueDay() + 1 - silicaV2_1.firstDueDay();
        uint256 initialCollateral = (((10 * silicaV2_1.resourceAmount() * networkReward * numDeposits) / (networkHashrate * 100)) *
            silicaV2_1.totalSupply()) / silicaV2_1.resourceAmount();
        uint256 initCollateralReleaseDay = numDeposits % 4 > 0
            ? silicaV2_1.firstDueDay() + 1 + (numDeposits / 4)
            : silicaV2_1.firstDueDay() + (numDeposits / 4);
        uint256 finalCollateralReleaseDay = numDeposits % 2 > 0
            ? silicaV2_1.firstDueDay() + 1 + (numDeposits / 2)
            : silicaV2_1.firstDueDay() + (numDeposits / 2);

        if (numDeposits == 2) {
            finalCollateralReleaseDay += 1;
        }

        if (day >= finalCollateralReleaseDay) {
            return (0);
        }
        if (day >= initCollateralReleaseDay) {
            return ((3 * initialCollateral) / 4);
        }
        return (initialCollateral);
    }

    function getSharesMintedWhenDeposit(address silicaAddress, uint256 amountSpecified) public view returns (uint256 sharesMinted) {
        SilicaV2_1 silicaV2_1 = SilicaV2_1(silicaAddress);

        uint256 reservedPrice = silicaV2_1.reservedPrice();
        uint256 resourceAmount = silicaV2_1.resourceAmount();

        sharesMinted = (amountSpecified * resourceAmount) / reservedPrice;
    }

    function getReservedPrice(address silicaAddress, uint256 unitPrice) public view returns (uint256 reservedPrice) {
        SilicaV2_1 silicaV2_1 = SilicaV2_1(silicaAddress);

        uint256 hashrate = silicaV2_1.resourceAmount();
        uint256 numDueDay = silicaV2_1.lastDueDay() + 1 - silicaV2_1.firstDueDay();

        reservedPrice = (hashrate * unitPrice * numDueDay) / 10**(silicaV2_1.decimals());
    }

    function getInitialCollateral(address silicaAddress, address oracleAddress) public view returns (uint256 initialCollateral) {
        SilicaV2_1 silicaV2_1 = SilicaV2_1(silicaAddress);
        Oracle oracle = Oracle(oracleAddress);

        uint256 numDueDay = silicaV2_1.lastDueDay() + 1 - silicaV2_1.firstDueDay();
        (, , uint256 networkHashrate, uint256 networkReward, , , ) = oracle.get(oracle.getLastIndexedDay());
        uint256 hashrate = silicaV2_1.resourceAmount();

        initialCollateral = (10 * hashrate * networkReward * numDueDay) / (networkHashrate * 100);
    }

    function getInitialCollateralEthStaking(address silicaAddress, address oracleAddress) public view returns (uint256 initialCollateral) {
        SilicaEthStaking silicaEthStaking = SilicaEthStaking(silicaAddress);
        OracleEthStaking oracleEthStaking = OracleEthStaking(oracleAddress);

        uint256 numDueDay = silicaEthStaking.lastDueDay() + 1 - silicaEthStaking.firstDueDay();
        (, uint256 baseRewardPerIncrementPerDay, , , , , ) = oracleEthStaking.get(oracleEthStaking.getLastIndexedDay());
        uint256 stakedAmount = silicaEthStaking.resourceAmount();

        initialCollateral = (numDueDay * baseRewardPerIncrementPerDay * stakedAmount) / (10**(silicaEthStaking.decimals() + 1));
    }
}