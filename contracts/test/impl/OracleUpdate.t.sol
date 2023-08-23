pragma solidity 0.8.19;

import "../base/BaseTest.t.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OracleUpdate is BaseTest {

    uint32  referenceBlock = 4242;
    uint32  timestamp = 1;
    uint128 hashrate = 1000;
    uint64  difficulty = 13000;
    uint256 reward = 1000;
    uint256 fees = 10000;
    bytes signature;

    function setUp() public override {
        super.setUp();
    }

    function testUpdateRewardTokenOracleIndex() public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(uint256(42), uint256(referenceBlock), uint256(hashrate),  reward, fees, uint256(difficulty))
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        rewardTokenOracle.updateIndex(
            42,
            uint256(referenceBlock),
            uint256(hashrate),
            reward,
            fees,
            uint256(difficulty),
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        assertEq(rewardTokenOracle.getLastIndexedDay(), 42);
        assertTrue(rewardTokenOracle.isDayIndexed(42));

        (
            uint256 indexedReferenceDay,
            uint256 indexedReferenceBlock,
            uint256 indexedHashrate,
            uint256 indexedReward,
            uint256 indexedFees,
            uint256 indexedDifficulty,
            uint256 indexedTimestamp
        ) = rewardTokenOracle.get(42);

        assertEq(indexedReferenceDay, 42);
        assertEq(indexedReferenceBlock, referenceBlock);
        assertEq(indexedHashrate, hashrate);
        assertEq(indexedReward, reward);
        assertEq(indexedFees, fees);
        assertEq(indexedDifficulty, difficulty);
        assertEq(indexedTimestamp, block.timestamp);
    }

    function testFuzzUpdateRewardTokenOracleIndexDay(
      uint256 _referenceDay,
      uint32  _referenceBlock,
      uint128 _hashrate,
      uint64  _difficulty,
      uint256 _reward,
      uint256 _fees) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        rewardTokenOracle.updateIndex(
            _referenceDay,
            _referenceBlock, 
            _hashrate, 
            _reward, 
            _fees, 
            _difficulty,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        assertTrue(rewardTokenOracle.isDayIndexed(_referenceDay));

        (
            uint256 indexedReferenceDay,,,,,,
        ) = rewardTokenOracle.get(_referenceDay);

        assertEq(indexedReferenceDay, _referenceDay);
    }

    function testFuzzUpdateRewardTokenOracleIndexBlock(
      uint256 _referenceDay,
      uint32  _referenceBlock,
      uint128 _hashrate,
      uint64  _difficulty,
      uint256 _reward,
      uint256 _fees) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        rewardTokenOracle.updateIndex(
            _referenceDay,
            _referenceBlock, 
            _hashrate, 
            _reward, 
            _fees, 
            _difficulty,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        (
            ,uint256 indexedReferenceBlock,,,,,
        ) = rewardTokenOracle.get(_referenceDay);

        assertEq(indexedReferenceBlock, _referenceBlock);
    }

    function testFuzzUpdateRewardTokenOracleIndexHashrate(
      uint256 _referenceDay,
      uint32  _referenceBlock,
      uint128 _hashrate,
      uint64  _difficulty,
      uint256 _reward,
      uint256 _fees) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        rewardTokenOracle.updateIndex(
            _referenceDay,
            _referenceBlock, 
            _hashrate, 
            _reward, 
            _fees, 
            _difficulty,
            oracleCalculatorSignature
        );
        cheats.stopPrank();
      
        assertTrue(rewardTokenOracle.isDayIndexed(_referenceDay));

        (
            ,,uint256 indexedHashrate,,,,
        ) = rewardTokenOracle.get(_referenceDay);
        
        assertEq(indexedHashrate, _hashrate);
    }

    function testFuzzUpdateRewardTokenOracleIndexDifficulty(
      uint256 _referenceDay,
      uint32  _referenceBlock,
      uint128 _hashrate,
      uint64  _difficulty,
      uint256 _reward,
      uint256 _fees) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        rewardTokenOracle.updateIndex(
            _referenceDay,
            _referenceBlock, 
            _hashrate, 
            _reward, 
            _fees, 
            _difficulty,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        assertTrue(rewardTokenOracle.isDayIndexed(_referenceDay));

        (
            ,,,,,uint256 indexedDifficulty,
        ) = rewardTokenOracle.get(_referenceDay);

        assertEq(indexedDifficulty, _difficulty);
    }

    function testFuzzUpdateRewardTokenOracleIndexReward(
      uint256  _referenceDay,
      uint32  _referenceBlock,
      uint128 _hashrate,
      uint64  _difficulty,
      uint256 _reward,
      uint256 _fees) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        rewardTokenOracle.updateIndex(
            _referenceDay,
            _referenceBlock, 
            _hashrate, 
            _reward, 
            _fees, 
            _difficulty,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        (
            ,,,uint256 indexedReward,,,
        ) = rewardTokenOracle.get(_referenceDay);

        assertEq(indexedReward, _reward);
    }

    function testFuzzUpdateRewardTokenOracleIndexFees(
      uint256 _referenceDay,
      uint32  _referenceBlock,
      uint128 _hashrate,
      uint64  _difficulty,
      uint256 _reward,
      uint256 _fees) public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(_referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oraclePublisherAddress);

        rewardTokenOracle.updateIndex(
            _referenceDay,
            _referenceBlock, 
            _hashrate, 
            _reward, 
            _fees, 
            _difficulty,
            oracleCalculatorSignature
        );
        cheats.stopPrank();

        (
            ,,,, uint256 indexedFees,,
        ) = rewardTokenOracle.get(_referenceDay);

        assertEq(indexedFees, _fees);
    }

    function testInvalidCalculatorSignature() public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(uint256(42), uint256(referenceBlock), uint256(hashrate),  reward, fees, uint256(difficulty))
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oraclePublisherPrivateKey, messageHash);
        bytes memory oraclePublisherSignature = abi.encodePacked(r, s, v);
        cheats.startPrank(oraclePublisherAddress);

        cheats.expectRevert("Invalid signature");
        rewardTokenOracle.updateIndex(
            42,
            uint256(referenceBlock),
            uint256(hashrate),
            reward,
            fees,
            uint256(difficulty),
            oraclePublisherSignature
        );
        cheats.stopPrank();
    }

    function testInvalidPublisherSignature() public {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(uint256(42), uint256(referenceBlock), uint256(hashrate),  reward, fees, uint256(difficulty))
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
        bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

        cheats.startPrank(oracleCalculatorAddress);

        cheats.expectRevert("Update not allowed to everyone");
        rewardTokenOracle.updateIndex(
            42,
            uint256(referenceBlock),
            uint256(hashrate),
            reward,
            fees,
            uint256(difficulty),
            oracleCalculatorSignature
        );
        cheats.stopPrank();
    }

    function testRewardOracleGetInRange() public {
        uint256 daysToPopulate = 5;
        for (uint256 i = 0; i < daysToPopulate; i++) {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encode(uint256(42+i), uint256(referenceBlock), uint256(hashrate),  reward, fees, uint256(difficulty))
                    )
                )
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
            bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

            cheats.startPrank(oraclePublisherAddress);

            rewardTokenOracle.updateIndex(
               42+i,
               uint256(referenceBlock),
               uint256(hashrate),
               reward,
               fees,
               uint256(difficulty),
               oracleCalculatorSignature
            );
            cheats.stopPrank();
        }

        (uint256[] memory hashrateArray, uint256[] memory rewardArray) = rewardTokenOracle.getInRange(42, 42 + daysToPopulate - 1);
        uint32 lastIndexedDay = rewardTokenOracle.getLastIndexedDay();
        assertEq(lastIndexedDay, 42 + daysToPopulate - 1);

        for (uint256 i = 0; i < daysToPopulate; i++) {
            assertEq(hashrateArray[i], hashrate);
        }

        for (uint256 i = 0; i < daysToPopulate; i++) {
            assertEq(rewardArray[i], reward);
        }
    }

    function testGetInRangeWithMissingData() public {
        uint256 daysToPopulate = 5;
        for (uint256 i = 0; i < daysToPopulate; i += 2) {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encode(uint256(42+i), uint256(referenceBlock+i), uint256(hashrate+i), reward+i, fees+i, uint256(difficulty+i))
                    )
                )
            );

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(oracleCalculatorPrivateKey, messageHash);
            bytes memory oracleCalculatorSignature = abi.encodePacked(r, s, v);

            cheats.startPrank(oraclePublisherAddress);

            rewardTokenOracle.updateIndex(
               42+i,
               uint256(referenceBlock)+i,
               uint256(hashrate)+i,
               reward+i,
               fees+i,
               uint256(difficulty)+i,
               oracleCalculatorSignature
            );
            cheats.stopPrank();
        }

        cheats.expectRevert("Missing data in range");

        oracleEthStaking.getInRange(42, 42 + daysToPopulate - 1);
    }
}