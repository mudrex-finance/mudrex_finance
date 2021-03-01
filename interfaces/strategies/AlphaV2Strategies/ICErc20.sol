// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ICErc20 {
    function exchangeRateStored() external view returns (uint256);
}