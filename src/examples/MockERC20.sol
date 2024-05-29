// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockERC20
/// @notice A mock ERC20 token for testing or demo purposes. Any amount can be minted by any account.
contract MockERC20 is ERC20 {
    /// @notice Constructor that initializes the ERC20 token with a name, symbol, and initial supply.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param supply The initial supply of tokens to mint.
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }

    /// @notice Mints a specified amount of tokens to the caller's address.
    /// @param _amount The amount of tokens to mint.
    function mint(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
}