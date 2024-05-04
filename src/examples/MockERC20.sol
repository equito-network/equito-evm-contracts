// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// A mock ERC20 token for testing or demo purposes.
/// Any amount can be minted by any account.
contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }

    function mint(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
}
