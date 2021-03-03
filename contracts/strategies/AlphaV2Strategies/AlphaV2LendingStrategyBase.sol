// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/math/Math.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/math/SafeMath.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/utils/Address.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/token/ERC20/SafeERC20.sol";
import "../../../interfaces/strategies/AlphaV2Strategies/IAlphaV2.sol";
import "../../../interfaces/strategies/AlphaV2Strategies/ICErc20.sol";
import "../../../interfaces/IFund.sol";
import "../../../interfaces/IStrategy.sol";
import "../../../interfaces/IGovernable.sol";

/**
* This strategy takes an asset (DAI, USDC), lends to AlphaV2 Lending Box.
*/
contract AlphaV2LendingStrategyBase is IStrategy {

  enum TokenIndex {DAI, USDC}

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public override underlying;
  address public override fund;
  address public override creator;

  // the matching enum record used to determine the index
  TokenIndex tokenIndex;

  // the alphasafebox corresponding to the underlying asset
  address public aBox;

  // these tokens cannot be claimed by the governance
  mapping(address => bool) public unsalvagableTokens;

  bool public investActivated;

  constructor(
    address _fund,
    address _aBox,
    uint256 _tokenIndex
  ) public {
    require(_fund != address(0), "Fund cannot be empty");
    fund = _fund;
    underlying = IFund(fund).underlying();
    tokenIndex = TokenIndex(_tokenIndex);
    aBox = _aBox;
    creator = msg.sender;

    // set these tokens to be not salvageable
    unsalvagableTokens[underlying] = true;
    unsalvagableTokens[aBox] = true;

    investActivated = true;
  }

  function governance() internal view returns(address) {
    return IGovernable(fund).governance();
  }

  modifier onlyFundOrGovernance() {
    require(msg.sender == fund || msg.sender == governance(),
      "The sender has to be the governance or fund");
    _;
  }

  /**
  *  TODO
  */
  function depositArbCheck() public override view returns(bool) {
    return true;
  }

  /**
  * Allows Governance to withdraw partial shares to reduce slippage incurred 
  *  and facilitate migration / withdrawal / strategy switch
  */
  function withdrawPartialShares(uint256 shares) external onlyFundOrGovernance {
    IAlphaV2(aBox).withdraw(shares);
  }


  function setInvestActivated(bool _investActivated) external onlyFundOrGovernance {
    investActivated = _investActivated;
  }

  /**
  * Withdraws an underlying asset from the strategy to the fund in the specified amount.
  * It tries to withdraw from the strategy contract if this has enough balance.
  * Otherwise, we withdraw shares from the Alpha V2 Lending Box. Transfer the required underlying amount to fund, 
  * and reinvest the rest. We can make it better by calculating the correct amount and withdrawing only that much.
  */
  function withdrawToFund(uint256 underlyingAmount) override external onlyFundOrGovernance {
    
    uint256 underlyingBalanceBefore = IERC20(underlying).balanceOf(address(this));
    
    if(underlyingBalanceBefore >= underlyingAmount) {
      IERC20(underlying).safeTransfer(fund, underlyingAmount);
      return;
    }

    uint256 shares = shareValueFromUnderlying(underlyingAmount.sub(underlyingBalanceBefore));
    IAlphaV2(aBox).withdraw(shares);
    
    // we can transfer the asset to the fund
    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      IERC20(underlying).safeTransfer(fund, Math.min(underlyingAmount, underlyingBalance));
    }
  }

  /**
  * Withdraws all assets from the Alpha V2 Lending Box and transfers to Fund.
  */
  function withdrawAllToFund() external override onlyFundOrGovernance {
    uint256 shares = IAlphaV2(aBox).balanceOf(address(this));
    IAlphaV2(aBox).withdraw(shares);
    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      IERC20(underlying).safeTransfer(fund, underlyingBalance);
    }
  }

  /**
  * Invests all underlying assets into our Alpha V2 Lending Box.
  */
  function investAllUnderlying() internal {
    if(!investActivated) {
      return;
    }

    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      IERC20(underlying).safeApprove(aBox, 0);
      IERC20(underlying).safeApprove(aBox, underlyingBalance);
      // deposits the entire balance to Alpha V2 Lending Box
      IAlphaV2(aBox).deposit(underlyingBalance);
    }
  }

  /**
  * The hard work only invests all underlying assets
  */
  function doHardWork() public override onlyFundOrGovernance {
    investAllUnderlying();
  }

  // no tokens apart from underlying should be sent to this contract. Any tokens that are sent here by mistake are recoverable by governance
  function sweep(address _token, address _sweepTo) external {
    require(governance() == msg.sender, "Not governance");
    require(!unsalvagableTokens[_token], "token is defined as not salvageable");
    IERC20(_token).safeTransfer(_sweepTo, IERC20(_token).balanceOf(address(this)));
  }

  /**
  * Keeping this here as I did not find how to get totalReward */
  function claim(uint256 totalReward, bytes32[] memory proof) external onlyFundOrGovernance { 
    IAlphaV2(aBox).claim(totalReward, proof);
  }

  /**
  * Returns the underlying invested balance. This is the underlying amount based on yield bearing token balance,
  * plus the current balance of the underlying asset.
  */
  function investedUnderlyingBalance() external override view returns (uint256) {
    uint256 shares = IERC20(aBox).balanceOf(address(this));
    address cToken = IAlphaV2(aBox).cToken();
    uint256 exchangeRate = ICErc20(cToken).exchangeRateStored();
    uint256 precision = 10 ** 18;
    uint256 underlyingBalanceinABox = shares.mul(exchangeRate).div(precision);
    return underlyingBalanceinABox.add(IERC20(underlying).balanceOf(address(this)));
  }

  /**
  * Returns the value of the underlying token in aBox ibToken
  */
  function shareValueFromUnderlying(uint256 underlyingAmount) internal view returns (uint256) {
    return underlyingAmount
      .mul(10 ** 18)
      .div(ICErc20(IAlphaV2(aBox).cToken()).exchangeRateStored());
  }
}
