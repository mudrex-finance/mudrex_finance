// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/math/Math.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/math/SafeMath.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/utils/Address.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/token/ERC20/SafeERC20.sol";
import "../../../interfaces/strategies/YearnV2Strategies/IYVaultV2.sol";
import "../../../interfaces/IFund.sol";
import "../../../interfaces/IStrategy.sol";
import "../../../interfaces/IGovernable.sol";

/**
* This strategy takes an asset (DAI, USDC), deposits into yv2 vault. Currently building only for DAI.
*/
contract YearnV2StrategyBase is IStrategy {

  enum TokenIndex {DAI, USDC}

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public override underlying;
  address public override fund;
  address public override creator;

  // the matching enum record used to determine the index
  TokenIndex tokenIndex;

  // the y-vault corresponding to the underlying asset
  address public yVault;

  // these tokens cannot be claimed by the governance
  mapping(address => bool) public unsalvagableTokens;

  bool public investActivated;

  constructor(
    address _fund,
    address _yVault,
    uint256 _tokenIndex
  ) public {
    fund = _fund;
    underlying = IFund(fund).underlying();
    tokenIndex = TokenIndex(_tokenIndex);
    yVault = _yVault;
    creator = msg.sender;

    // set these tokens to be not salvageable
    unsalvagableTokens[underlying] = true;
    unsalvagableTokens[yVault] = true;

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
    IYVaultV2(yVault).withdraw(shares);
  }


  function setInvestActivated(bool _investActivated) external onlyFundOrGovernance {
    investActivated = _investActivated;
  }

  /**
  * Withdraws an underlying asset from the strategy to the fund in the specified amount.
  * It tries to withdraw from the strategy contract if this has enough balance.
  * Otherwise, we withdraw shares from the yv2 vault. Transfer the required underlying amount to fund, 
  * and reinvest the rest. We can make it better by calculating the correct amount and withdrawing only that much.
  */
  function withdrawToFund(uint256 underlyingAmount) override external onlyFundOrGovernance {
    
    uint256 underlyingBalanceBefore = IERC20(underlying).balanceOf(address(this));
    
    if(underlyingBalanceBefore >= underlyingAmount) {
      IERC20(underlying).safeTransfer(fund, underlyingAmount);
      return;
    }

    uint256 shares = shareValueFromUnderlying(underlyingAmount.sub(underlyingBalanceBefore));
    IYVaultV2(yVault).withdraw(shares);
    
    // we can transfer the asset to the fund
    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      IERC20(underlying).safeTransfer(fund, Math.min(underlyingAmount, underlyingBalance));
    }
  }

  /**
  * Withdraws all assets from the yv2 vault and transfer to fund.
  */
  function withdrawAllToFund() external override onlyFundOrGovernance {
    uint256 shares = IYVaultV2(yVault).balanceOf(address(this));
    IYVaultV2(yVault).withdraw(shares);
    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      IERC20(underlying).safeTransfer(fund, underlyingBalance);
    }
  }

  /**
  * Invests all underlying assets into our yv2 vault.
  */
  function investAllUnderlying() internal {
    if(!investActivated) {
      return;
    }
    
    require(!IYVaultV2(yVault).emergencyShutdown(), "Vault is emergency shutdown");

    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      IERC20(underlying).safeApprove(yVault, 0);
      IERC20(underlying).safeApprove(yVault, underlyingBalance);
      // deposits the entire balance to yv2 vault
      IYVaultV2(yVault).deposit(underlyingBalance);
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
  * Returns the underlying invested balance. This is the underlying amount based on shares in the yv2 vault,
  * plus the current balance of the underlying asset.
  */
  function investedUnderlyingBalance() external override view returns (uint256) {
    uint256 shares = IERC20(yVault).balanceOf(address(this));
    uint256 price = IYVaultV2(yVault).pricePerShare();
    uint256 precision = 10 ** 18;
    uint256 underlyingBalanceinYVault = shares.mul(price).div(precision);
    return underlyingBalanceinYVault.add(IERC20(underlying).balanceOf(address(this)));
  }


  /**
  * Returns the value of the underlying token in yToken
  */
  function shareValueFromUnderlying(uint256 underlyingAmount) internal view returns (uint256) {
    // 1 yToken = this much underlying, 10 ** 18 precision for all tokens
    return underlyingAmount
      .mul(10 ** 18)
      .div(IYVaultV2(yVault).pricePerShare());
  }
}
