// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@std/Test.sol";
import "../../../OracleRegistry.sol";
import "../OracleRegistryStorage.t.sol";

contract TestOracleRegistry is Test {
  using OracleRegistryStorage for OracleRegistry;

  OracleRegistry testOracleRegistry;

  function setUp() public {
    testOracleRegistry = new OracleRegistry();
  }

  function testSetOwner() public {
    testOracleRegistry.setOwner(address(this));
    assertEq(testOracleRegistry.owner(), address(this));
  }

  function testFuzzSetOwner(address _owner) public {
    vm.assume(_owner != address(0));
    testOracleRegistry.setOwner(_owner);
    assertEq(testOracleRegistry.owner(), _owner);
  }

  function testSetOracle() public {
    testOracleRegistry.setOracle(
      0x07865c6E87B9F70255377e024ace6630C1Eaa37F, // Goerli USDC address
      0,
      address(this));
    assertEq(testOracleRegistry.oracleRegistry(0x07865c6E87B9F70255377e024ace6630C1Eaa37F, 0), address(this));
  }

  function testFuzzSetOracleSelectedComodityTypes(address _rewToken, uint16 _type, address _oracle) public {
    vm.assume(_type == 0 || _type == 2);
    testOracleRegistry.setOracle(
      _rewToken, // Goerli USDC address
      _type,
      _oracle);
    assertEq(testOracleRegistry.oracleRegistry(_rewToken, _type), _oracle);
  }

  function testFuzzSetOracle(address _rewToken, uint16 _type, address _oracle) public {
    testOracleRegistry.setOracle(
      _rewToken, // Goerli USDC address
      _type,
      _oracle);
    assertEq(testOracleRegistry.oracleRegistry(_rewToken, _type), _oracle);
  }
}