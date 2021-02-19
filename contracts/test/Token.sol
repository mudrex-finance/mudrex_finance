// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/presets/ERC20PresetMinterPauser.sol";

contract Token is ERC20PresetMinterPauser{
    constructor(string memory _name, string memory _symbol)
     ERC20PresetMinterPauser(_name, _symbol) public {
    }
}