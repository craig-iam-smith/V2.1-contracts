pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OracleEthStakingUpdate is BaseTest {
    uint256 referenceDay = 40;
    uint256 baseRewardPerIncrementPerDay = 1500000000;
    uint256 burnFee = 1000000000;
    uint256 priorityFee = 1300000000;
    uint256 burnFeeNormalized = 1000000000;
    uint256 priorityFeeNormalized = 1000000000;
    bytes signature;

    function setUp() public override {
        super.setUp();
    }

    function testUpdateIndex() public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(referenceDay, baseRewardPerIncrementPerDay, burnFee, priorityFee, burnFeeNormalized, priorityFeeNormalized)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        oracleEthStaking.updateIndex(
            referenceDay,
            baseRewardPerIncrementPerDay,
            burnFee,
            priorityFee,
            burnFeeNormalized,
            priorityFeeNormalized,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        assertEq(oracleEthStaking.getLastIndexedDay(), referenceDay);
        assertTrue(oracleEthStaking.isDayIndexed(referenceDay));

        (
            uint256 indexedReferenceDay,
            uint256 indexedBaseRewardPerIncrementPerDay,
            uint256 indexedBurnFee,
            uint256 indexedPriorityFee,
            uint256 indexedBurnFeeNormalized,
            uint256 indexedPriorityFeeNormalized,
            uint256 indexedTimestamp
        ) = oracleEthStaking.get(referenceDay);

        assertEq(indexedReferenceDay, referenceDay);
        assertEq(indexedBaseRewardPerIncrementPerDay, baseRewardPerIncrementPerDay);
        assertEq(indexedBurnFee, burnFee);
        assertEq(indexedPriorityFee, priorityFee);
        assertEq(indexedBurnFeeNormalized, burnFeeNormalized);
        assertEq(indexedPriorityFeeNormalized, priorityFeeNormalized);
        assertEq(indexedTimestamp, block.timestamp);
    }

    function testFuzzUpdateIndexDay(
        uint256 _referenceDay,
        uint256 _baseRewardPerIncrementPerDay,
        uint256 _burnFee,
        uint256 _priorityFee,
        uint256 _burnFeeNormalized,
        uint256 _priorityFeeNormalized
    ) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _baseRewardPerIncrementPerDay, _burnFee, _priorityFee, _burnFeeNormalized, _priorityFeeNormalized)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        oracleEthStaking.updateIndex(
            _referenceDay,
            _baseRewardPerIncrementPerDay,
            _burnFee,
            _priorityFee,
            _burnFeeNormalized,
            _priorityFeeNormalized,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        (
            uint256 indexedReferenceDay,,,,,,
        ) = oracleEthStaking.get(_referenceDay);

        assertEq(indexedReferenceDay, _referenceDay);
    }

    function testFuzzUpdateIndexReward(
        uint256 _referenceDay,
        uint256 _baseRewardPerIncrementPerDay,
        uint256 _burnFee,
        uint256 _priorityFee,
        uint256 _burnFeeNormalized,
        uint256 _priorityFeeNormalized
    ) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _baseRewardPerIncrementPerDay, _burnFee, _priorityFee, _burnFeeNormalized, _priorityFeeNormalized)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        oracleEthStaking.updateIndex(
            _referenceDay,
            _baseRewardPerIncrementPerDay,
            _burnFee,
            _priorityFee,
            _burnFeeNormalized,
            _priorityFeeNormalized,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        (
            ,
            uint256 indexedBaseRewardPerIncrementPerDay,
            ,,,,
        ) = oracleEthStaking.get(_referenceDay);

        assertEq(indexedBaseRewardPerIncrementPerDay, _baseRewardPerIncrementPerDay);
    }

    function testInvalidCalculatorSignature() public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(referenceDay, baseRewardPerIncrementPerDay, burnFee, priorityFee, burnFeeNormalized, priorityFeeNormalized)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oraclePublisherPrivateKey, messageHash);
        bytes memory oraclePublisherSignature = abi.encodePacked(r, s, v);
        cheats.startPrank(oraclePublisherAddress);

        cheats.expectRevert("Invalid signature");
        oracleEthStaking.updateIndex(
            referenceDay,
            baseRewardPerIncrementPerDay,
            burnFee,
            priorityFee,
            burnFeeNormalized,
            priorityFeeNormalized,
            oraclePublisherSignature
        );
        cheats.stopPrank();
    }

    function testFuzzUpdateIndexBurn(
        uint256 _referenceDay,
        uint256 _baseRewardPerIncrementPerDay,
        uint256 _burnFee,
        uint256 _priorityFee,
        uint256 _burnFeeNormalized,
        uint256 _priorityFeeNormalized
    ) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _baseRewardPerIncrementPerDay, _burnFee, _priorityFee, _burnFeeNormalized, _priorityFeeNormalized)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        oracleEthStaking.updateIndex(
            _referenceDay,
            _baseRewardPerIncrementPerDay,
            _burnFee,
            _priorityFee,
            _burnFeeNormalized,
            _priorityFeeNormalized,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        (
            ,,uint256 indexedBurnFee,,,,
        ) = oracleEthStaking.get(_referenceDay);

        assertEq(indexedBurnFee, _burnFee);
    }

    function testFuzzUpdateIndexPriority(
        uint256 _referenceDay,
        uint256 _baseRewardPerIncrementPerDay,
        uint256 _burnFee,
        uint256 _priorityFee,
        uint256 _burnFeeNormalized,
        uint256 _priorityFeeNormalized
    ) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _baseRewardPerIncrementPerDay, _burnFee, _priorityFee, _burnFeeNormalized, _priorityFeeNormalized)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        oracleEthStaking.updateIndex(
            _referenceDay,
            _baseRewardPerIncrementPerDay,
            _burnFee,
            _priorityFee,
            _burnFeeNormalized,
            _priorityFeeNormalized,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        (
            ,,,
            uint256 indexedPriorityFee,
            ,,
        ) = oracleEthStaking.get(_referenceDay);

        assertEq(indexedPriorityFee, _priorityFee);
    }

    function testFuzzUpdateIndexBurnNormalized(
        uint256 _referenceDay,
        uint256 _baseRewardPerIncrementPerDay,
        uint256 _burnFee,
        uint256 _priorityFee,
        uint256 _burnFeeNormalized,
        uint256 _priorityFeeNormalized
    ) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _baseRewardPerIncrementPerDay, _burnFee, _priorityFee, _burnFeeNormalized, _priorityFeeNormalized)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        oracleEthStaking.updateIndex(
            _referenceDay,
            _baseRewardPerIncrementPerDay,
            _burnFee,
            _priorityFee,
            _burnFeeNormalized,
            _priorityFeeNormalized,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        (
            ,,,,uint256 indexedBurnFeeNormalized,,
        ) = oracleEthStaking.get(_referenceDay);

        assertEq(indexedBurnFeeNormalized, _burnFeeNormalized);
    }

    function testFuzzUpdateIndexPriorityNormalized(
        uint256 _referenceDay,
        uint256 _baseRewardPerIncrementPerDay,
        uint256 _burnFee,
        uint256 _priorityFee,
        uint256 _burnFeeNormalized,
        uint256 _priorityFeeNormalized
    ) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _baseRewardPerIncrementPerDay, _burnFee, _priorityFee, _burnFeeNormalized, _priorityFeeNormalized)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        oracleEthStaking.updateIndex(
            _referenceDay,
            _baseRewardPerIncrementPerDay,
            _burnFee,
            _priorityFee,
            _burnFeeNormalized,
            _priorityFeeNormalized,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        (
            ,,,,,uint256 indexedPriorityFeeNormalized,
        ) = oracleEthStaking.get(_referenceDay);

        assertEq(indexedPriorityFeeNormalized, _priorityFeeNormalized);
    }

    function testInvalidPublisherSignature() public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(referenceDay, baseRewardPerIncrementPerDay, burnFee, priorityFee, burnFeeNormalized, priorityFeeNormalized)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oracleCalculatorAddress);

        cheats.expectRevert("Update not allowed to everyone");
        oracleEthStaking.updateIndex(
            referenceDay,
            baseRewardPerIncrementPerDay,
            burnFee,
            priorityFee,
            burnFeeNormalized,
            priorityFeeNormalized,
            oracleCalculatorSignature
        );
        cheats.stopPrank();
    }

    function testGetInRange() public {
        uint256 daysToPopulate = 5;
        for (uint256 i = 0; i < daysToPopulate; i++) {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encode(
                            referenceDay + i,
                            baseRewardPerIncrementPerDay + i,
                            burnFee + i,
                            priorityFee + i,
                            burnFeeNormalized + i,
                            priorityFeeNormalized + i
                        )
                    )
                )
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
            bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

            cheats.startPrank(oraclePublisherAddress);

            oracleEthStaking.updateIndex(
                referenceDay + i,
                baseRewardPerIncrementPerDay + i,
                burnFee + i,
                priorityFee + i,
                burnFeeNormalized + i,
                priorityFeeNormalized + i,
                oracleCalculatorSignature
            );
            cheats.stopPrank();
        }

        uint256[] memory baseRewardPerIncrementPerDayArray = oracleEthStaking.getInRange(referenceDay, referenceDay + daysToPopulate - 1);
        uint32 lastIndexedDay = oracleEthStaking.getLastIndexedDay();
        assertEq(lastIndexedDay, referenceDay + daysToPopulate - 1);
        for (uint256 i = 0; i < daysToPopulate; i++) {
            assertEq(baseRewardPerIncrementPerDayArray[i], baseRewardPerIncrementPerDay + i);
        }
    }

    function testGetInRangeWithMissingData() public {
        uint256 daysToPopulate = 5;
        for (uint256 i = 0; i < daysToPopulate; i += 2) {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encode(
                            referenceDay + i,
                            baseRewardPerIncrementPerDay + i,
                            burnFee + i,
                            priorityFee + i,
                            burnFeeNormalized + i,
                            priorityFeeNormalized + i
                        )
                    )
                )
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
            bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

            cheats.startPrank(oraclePublisherAddress);

            oracleEthStaking.updateIndex(
                referenceDay + i,
                baseRewardPerIncrementPerDay + i,
                burnFee + i,
                priorityFee + i,
                burnFeeNormalized + i,
                priorityFeeNormalized + i,
                oracleCalculatorSignature
            );
            cheats.stopPrank();
        }

        cheats.expectRevert("Missing data in range");

        oracleEthStaking.getInRange(referenceDay, referenceDay + daysToPopulate - 1);
    }
}