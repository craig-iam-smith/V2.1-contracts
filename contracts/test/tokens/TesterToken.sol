// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TesterToken is ERC20 {
    uint8 public customDecimals;

    constructor(uint8 _decimals) ERC20("TesterToken", "TesterToken") {
        _mint(msg.sender, 2**255);
        customDecimals = _decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return customDecimals;
    }
}
