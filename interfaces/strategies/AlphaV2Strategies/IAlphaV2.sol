// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IAlphaV2 {
    // ERC20 part
    function balanceOf(address) external view returns (uint256);

    // AlphaV2 view interface
    function cToken() external view returns (address);

    // VaultV2 user interface
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function claim(uint totalReward, bytes32[] memory proof) external;
}