// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IYVaultV2 {
    // ERC20 part
    function balanceOf(address) external view returns (uint256);

    // VaultV2 view interface
    function emergencyShutdown() external view returns(bool);
    function pricePerShare() external view returns (uint256);

    // VaultV2 user interface
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
}