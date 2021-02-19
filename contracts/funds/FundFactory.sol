// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./FundProxy.sol";
import "./Fund.sol";
import "../utils/Governable.sol";

contract FundFactory is Governable {

  event NewFund(address fundProxy);

  constructor() public {
    Governable.initializeGovernance(
      msg.sender
    );
  }

  function createFund(
    address _implementation,
    address _underlying,
    string memory _name,
    string memory _symbol
  ) public onlyGovernance returns(address) {
    FundProxy proxy = new FundProxy(_implementation);
    Fund(address(proxy)).initializeFund(msg.sender,
      _underlying,
      _name,
      _symbol
    );
    emit NewFund(address(proxy));
    return address(proxy);
  }
}
