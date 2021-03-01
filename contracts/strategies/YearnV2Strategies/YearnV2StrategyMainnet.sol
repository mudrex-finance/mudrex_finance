// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./YearnV2StrategyBase.sol";

/**
* Adds the mainnet addresses to the YearnV2StrategyBase
*/
contract YearnV2StrategyMainnet is YearnV2StrategyBase {

  // token addresses
  // y-addresses are taken from: https://docs.yearn.finance/products/yvaults-1/v2-yvaults/strategies-and-yvaults-available
  address constant public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address constant public yvdai = address(0x19D3364A399d251E894aC732651be8B0E4e85001);
  address constant public usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant public yvusdc = address(0x5f18C75AbDAe578b483E5F43f12a39cF75b973a9);

  // pre-defined constant mapping: underlying -> y-token
  mapping(address => address) public yVaults;

  constructor(
    address _fund
  )
  YearnV2StrategyBase(_fund, address(0), 0)
  public {
    yVaults[dai] = yvdai;
    yVaults[usdc] = yvdai;
    yVault = yVaults[underlying];
    require(yVault != address(0), "underlying not supported: yVault is not defined");
    if (underlying == dai) {
      tokenIndex = TokenIndex.DAI;
    } else if (underlying == usdc) {
      tokenIndex = TokenIndex.USDC;
    } else {
      revert("Asset not supported");
    }
  }
}
