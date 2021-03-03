// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "OpenZeppelin/openzeppelin-contracts-upgradeable@3.4.0/contracts/proxy/Initializable.sol";

contract FundStorage is Initializable {

  bytes32 internal constant _UNDERLYING_SLOT = 0xb95b06046f468e8441830797ac9acc485ce2fadf4e07e35b01dc79368bf03188;
  bytes32 internal constant _UNDERLYING_UNIT_SLOT = 0xdb07622b1bd87eaa3d4422a4b4b176cf0a9fb09976d65f4178028ad157af3437;
  bytes32 internal constant _FUND_MANAGER_SLOT = 0x17f7ba76b5fc45dcfa067fab67ef2ac654842690c91910585d005e158d96eae3;
  bytes32 internal constant _REWARDS_SLOT = 0x58c27fef89139117534964873d9bc88d4e406f983b4f19ba70545153b1612ef3;
  bytes32 internal constant _DEPOSIT_LIMIT_SLOT = 0x1fc345aeacb2504bb144c6322cd6f959b8b22b7fa191c3f41903e75c2c0f868f;
  bytes32 internal constant _DEPOSIT_LIMIT_TX_MAX_SLOT = 0x8d1e87b0383d284ed35ad63c78444eea7be5fb8b2b84cef16330d84b40f3546b;
  bytes32 internal constant _DEPOSIT_LIMIT_TX_MIN_SLOT = 0x3f27a8341c446e0cdd0ab71b13137590d4aec3c514fdde59077ab96c7fe8e967;
  bytes32 internal constant _PERFORMANCE_FEE_FUND_SLOT = 0x67d7fa60453a87c46fdf39c2c97af9a4efa92447137fc01141db0c762bd177ed;
  bytes32 internal constant _PLATFORM_FEE_SLOT = 0xdb914d4ecf1b46de61e1ef0abb3324d8ae5bb0f8e2d834e2a2c8ef6347fad40a;
  bytes32 internal constant _WITHDRAWAL_FEE_SLOT = 0xf6e3df965b199051d61624db5fab1794c9669f468a90df79a78aa7b0e55b338a;
  bytes32 internal constant _MAX_INVESTMENT_IN_STRATEGIES_SLOT = 0xac70a1670fe19ee7e0602c0950417634b6584c7b4232fa5df9f49111c5557934;
  bytes32 internal constant _TOTAL_WEIGHT_IN_STRATEGIES_SLOT = 0x9133abd018b6fde28d66aca2ecd382fecf17ffa40fe22c4e0289322fefbd7b9e;
  bytes32 internal constant _TOTAL_ACCOUNTED_SLOT = 0x9ead72750dc13281a9f039b34e3371c56895558984b60f278cb7add9f9149177;
  bytes32 internal constant _TOTAL_INVESTED_SLOT = 0x98a6f29fda853c583d893d7dcade92c0eed126b239c85998829c2e1a68fac1b9;
  bytes32 internal constant _DEPOSITS_PAUSED_SLOT = 0x34b904506aeff8cce013d1019a67832c48d47a000b028cb65d615b851146b9e7;
  bytes32 internal constant _SHOULD_REBALANCE_SLOT = 0xdf9eebd73c8ef0a729535a9beb9ea86fe8f224c6cec5fa940c8f06696acf2b3f;
  bytes32 internal constant _LAST_HARDWORK_TIMESTAMP_SLOT = 0x8a707ee777f050560006c09cf98a16653902a051a88d4d43dcad61827e3ab091;

  constructor() public {
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.underlying")) - 1));
    assert(_UNDERLYING_UNIT_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.underlyingUnit")) - 1));
    assert(_FUND_MANAGER_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.fundManager")) - 1));
    assert(_REWARDS_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.rewards")) - 1));
    assert(_DEPOSIT_LIMIT_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.depositLimit")) - 1));
    assert(_DEPOSIT_LIMIT_TX_MAX_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.depositLimitTxMax")) - 1));
    assert(_DEPOSIT_LIMIT_TX_MIN_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.depositLimitTxMin")) - 1));
    assert(_PERFORMANCE_FEE_FUND_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.performanceFeeFund")) - 1));
    assert(_PLATFORM_FEE_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.platformFee")) - 1));
    assert(_WITHDRAWAL_FEE_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.withdrawalFee")) - 1));
    assert(_MAX_INVESTMENT_IN_STRATEGIES_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.maxInvestmentInStrategies")) - 1));
    assert(_TOTAL_WEIGHT_IN_STRATEGIES_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.totalWeightInStrategies")) - 1));
    assert(_TOTAL_ACCOUNTED_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.totalAccounted")) - 1));
    assert(_TOTAL_INVESTED_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.totalInvested")) - 1));
    assert(_DEPOSITS_PAUSED_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.depositsPaused")) - 1));
    assert(_SHOULD_REBALANCE_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.shouldRebalance")) - 1));
    assert(_LAST_HARDWORK_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.mudrex.finance.fundStorage.lastHardworkTimestamp")) - 1));
  }


  function initializeFundStorage(
    address _underlying,
    uint256 _underlyingUnit,
    address _fundManager,
    address _rewards
  ) public initializer {
    _setUnderlying(_underlying);
    _setUnderlyingUnit(_underlyingUnit);
    _setFundManager(_fundManager);
    _setRewards(_rewards);
    _setDepositLimit(0);
    _setDepositLimitTxMax(0);
    _setDepositLimitTxMin(0);
    _setPerformanceFeeFund(0);
    _setPlatformFee(0);
    _setWithdrawalFee(0);
    _setMaxInvestmentInStrategies(9000);   // 9000 BPS (90%) can be accessed by the strategies. This is to keep something in fund for withdrawal.
    _setTotalWeightInStrategies(0);
    _setTotalAccounted(0);
    _setTotalInvested(0);
    _setDepositsPaused(false);
    _setShouldRebalance(false);
    _setLastHardworkTimestamp(0);
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function _underlying() internal view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setUnderlyingUnit(uint256 _value) internal {
    setUint256(_UNDERLYING_UNIT_SLOT, _value);
  }

  function _underlyingUnit() internal view returns (uint256) {
    return getUint256(_UNDERLYING_UNIT_SLOT);
  }

  function _setFundManager(address _fundManager) internal {
    setAddress(_FUND_MANAGER_SLOT, _fundManager);
  }

  function _fundManager() internal view returns (address) {
    return getAddress(_FUND_MANAGER_SLOT);
  }

  function _setRewards(address _rewards) internal {
    setAddress(_REWARDS_SLOT, _rewards);
  }

  function _rewards() internal view returns (address) {
    return getAddress(_REWARDS_SLOT);
  }

  function _setDepositLimit(uint256 _value) internal {
    setUint256(_DEPOSIT_LIMIT_SLOT, _value);
  }

  function _depositLimit() internal view returns (uint256) {
    return getUint256(_DEPOSIT_LIMIT_SLOT);
  }

  function _setDepositLimitTxMax(uint256 _value) internal {
    setUint256(_DEPOSIT_LIMIT_TX_MAX_SLOT, _value);
  }

  function _depositLimitTxMax() internal view returns (uint256) {
    return getUint256(_DEPOSIT_LIMIT_TX_MAX_SLOT);
  }

  function _setDepositLimitTxMin(uint256 _value) internal {
    setUint256(_DEPOSIT_LIMIT_TX_MIN_SLOT, _value);
  }

  function _depositLimitTxMin() internal view returns (uint256) {
    return getUint256(_DEPOSIT_LIMIT_TX_MIN_SLOT);
  }

  function _setPerformanceFeeFund(uint256 _value) internal {
    setUint256(_PERFORMANCE_FEE_FUND_SLOT, _value);
  }

  function _performanceFeeFund() internal view returns (uint256) {
    return getUint256(_PERFORMANCE_FEE_FUND_SLOT);
  }

  function _setPlatformFee(uint256 _value) internal {
    setUint256(_PLATFORM_FEE_SLOT, _value);
  }

  function _platformFee() internal view returns (uint256) {
    return getUint256(_PLATFORM_FEE_SLOT);
  }

  function _setWithdrawalFee(uint256 _value) internal {
    setUint256(_WITHDRAWAL_FEE_SLOT, _value);
  }

  function _withdrawalFee() internal view returns (uint256) {
    return getUint256(_WITHDRAWAL_FEE_SLOT);
  }

  function _setMaxInvestmentInStrategies(uint256 _value) internal {
    setUint256(_MAX_INVESTMENT_IN_STRATEGIES_SLOT, _value);
  }

  function _maxInvestmentInStrategies() internal view returns (uint256) {
    return getUint256(_MAX_INVESTMENT_IN_STRATEGIES_SLOT);
  }

  function _setTotalWeightInStrategies(uint256 _value) internal {
    setUint256(_TOTAL_WEIGHT_IN_STRATEGIES_SLOT, _value);
  }

  function _totalWeightInStrategies() internal view returns (uint256) {
    return getUint256(_TOTAL_WEIGHT_IN_STRATEGIES_SLOT);
  }

  function _setTotalAccounted(uint256 _value) internal {
    setUint256(_TOTAL_ACCOUNTED_SLOT, _value);
  }

  function _totalAccounted() internal view returns (uint256) {
    return getUint256(_TOTAL_ACCOUNTED_SLOT);
  }

  function _setTotalInvested(uint256 _value) internal {
    setUint256(_TOTAL_INVESTED_SLOT, _value);
  }

  function _totalInvested() internal view returns (uint256) {
    return getUint256(_TOTAL_INVESTED_SLOT);
  }

  function _setDepositsPaused(bool _value) internal {
    setBool(_DEPOSITS_PAUSED_SLOT, _value);
  }

  function _depositsPaused() internal view returns (bool) {
    return getBool(_DEPOSITS_PAUSED_SLOT);
  }

  function _setShouldRebalance(bool _value) internal {
    setBool(_SHOULD_REBALANCE_SLOT, _value);
  }

  function _shouldRebalance() internal view returns (bool) {
    return getBool(_SHOULD_REBALANCE_SLOT);
  }

  function _setLastHardworkTimestamp(uint256 _value) internal {
    setUint256(_LAST_HARDWORK_TIMESTAMP_SLOT, _value);
  }

  function _lastHardworkTimestamp() internal view returns (uint256) {
    return getUint256(_LAST_HARDWORK_TIMESTAMP_SLOT);
  }

  function setAddress(bytes32 slot, address _address) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) private {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function setBool(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBool(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function getAddress(bytes32 slot) private view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) private view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  uint256[50] private big_empty_slot;
}
