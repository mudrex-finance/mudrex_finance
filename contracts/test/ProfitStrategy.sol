// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/presets/ERC20PresetMinterPauser.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/utils/Address.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/math/SafeMath.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IFund.sol";
import "../../interfaces/IGovernable.sol";


contract ProfitStrategy is IStrategy {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  uint256 internal constant MAX_BPS = 10000;   // 100% in basis points

  address public override underlying;
  address public override fund;
  address public override creator;
  
  uint256 accountedBalance;
  uint256 profitPerc;

  // These tokens cannot be claimed by the controller
  mapping (address => bool) public unsalvagableTokens;

  constructor(address _fund, uint256 _profitPerc) public {
    require(_fund != address(0), "Fund cannot be empty");
    // We assume that this contract is a minter on underlying
    fund = _fund;
    underlying = IFund(fund).underlying();
    profitPerc = _profitPerc;
    creator = msg.sender;
  }

  function governance() internal returns(address) {
    return IGovernable(fund).governance();
  }
  
  function depositArbCheck() public override view returns(bool) {
    return true;
  }

  modifier onlyFundOrGovernance() {
    require(msg.sender == fund || msg.sender == governance(),
      "The sender has to be the governance or fund");
    _;
  }
  
  /*
  * Returns the total invested amount.
  */
  function investedUnderlyingBalance() view public override returns (uint256) {
    // for real strategies, need to calculate the invested balance
    return IERC20(underlying).balanceOf(address(this));
  }

  /*
  * Invests all tokens that were accumulated so far
  */
  function investAllUnderlying() public {
    uint256 contribution = IERC20(underlying).balanceOf(address(this)).sub(accountedBalance);
    // add 10% to this strategy
    // We assume that this contract is a minter on underlying
    ERC20PresetMinterPauser(underlying).mint(address(this), contribution.mul(profitPerc).div(MAX_BPS));
    accountedBalance = IERC20(underlying).balanceOf(address(this));
  }

  /*
  * Cashes everything out and withdraws to the fund
  */
  function withdrawAllToFund() external override onlyFundOrGovernance {
    IERC20(underlying).safeTransfer(fund, IERC20(underlying).balanceOf(address(this)));
    accountedBalance = IERC20(underlying).balanceOf(address(this));
  }

  /*
  * Cashes some amount out and withdraws to the fund
  */
  function withdrawToFund(uint256 amount) external override onlyFundOrGovernance {
    IERC20(underlying).safeTransfer(fund, amount);
    accountedBalance = IERC20(underlying).balanceOf(address(this));
  }

  /*
  * Honest harvesting. It's not much, but it pays off
  */
  function doHardWork() external override onlyFundOrGovernance {
    // investAllUnderlying();   // call this externally for testing as profit geeneration should be after invesment
  }

  // no tokens apart from underlying should be sent to this contract. Any tokens that are sent here by mistake are recoverable by governance
  function sweep(address _token, address _sweepTo) external {
    require(governance() == msg.sender, "Not governance");
    require(_token != underlying, "can not sweep underlying");
    IERC20(_token).safeTransfer(_sweepTo, IERC20(_token).balanceOf(address(this)));
  }
}
