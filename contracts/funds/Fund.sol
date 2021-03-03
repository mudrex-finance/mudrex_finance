// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "OpenZeppelin/openzeppelin-contracts-upgradeable@3.4.0/contracts/utils/AddressUpgradeable.sol";
import "OpenZeppelin/openzeppelin-contracts-upgradeable@3.4.0/contracts/math/MathUpgradeable.sol";
import "OpenZeppelin/openzeppelin-contracts-upgradeable@3.4.0/contracts/math/SafeMathUpgradeable.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@3.4.0/contracts/token/ERC20/SafeERC20.sol";
import "OpenZeppelin/openzeppelin-contracts-upgradeable@3.4.0/contracts/token/ERC20/ERC20Upgradeable.sol";
import "OpenZeppelin/openzeppelin-contracts-upgradeable@3.4.0/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "../../interfaces/IFund.sol";
import "../../interfaces/IUpgradeSource.sol";
import "../../interfaces/IStrategy.sol";
import "../utils/Governable.sol";
import "./FundStorage.sol";

contract Fund is ERC20Upgradeable, ReentrancyGuardUpgradeable, IFund, IUpgradeSource, Governable, FundStorage {
  using SafeERC20 for IERC20;
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  event Withdraw(address indexed beneficiary, uint256 amount, uint256 fee);
  event Deposit(address indexed beneficiary, uint256 amount);
  event InvestInStrategy(address strategy, uint256 amount);
  event StrategyRewards(address strategy, uint256 profit, uint256 strategyCreatorFee);
  event FundManagerRewards(uint256 profitTotal, uint256 fundManagerFee);
  event PlatformRewards(uint256 lastBalance, uint256 timeElapsed, uint256 platformFee);
  event TestEvent(uint256 lastBalance, uint256 timeElapsed, uint256 platformFee, uint256 fundManagerFee);

  address internal constant ZERO_ADDRESS = address(0);

  uint256 internal constant MAX_BPS = 10000;   // 100% in basis points
  uint256 internal constant SECS_PER_YEAR = 31556952;  // 365.25 days from yearn
  
  uint256 internal constant MAX_PLATFORM_FEE = 500;  // 5% (annual on AUM), goes to governance/treasury
  uint256 internal constant MAX_PERFORMANCE_FEE_FUND = 1000;  // 10% on profits, goes to fund manager
  uint256 internal constant MAX_PERFORMANCE_FEE_STRATEGY = 1000;  // 10% on profits, goes to strategy creator
  uint256 internal constant MAX_WITHDRAWAL_FEE = 100;  // 1%, goes to governance/treasury

  struct StrategyParams {
    uint256 weightage;  // weightage of total assets in fund this strategy can access (in BPS) (5000 for 50%)
    uint256 performanceFeeStrategy;   // in BPS, fee on yield of the strategy, goes to strategy creator
    uint256 activation;  // timestamp when strategy is added
    uint256 lastBalance;    // balance at last hard work
    uint256 indexInList;
  }

  mapping(address => StrategyParams) public strategies;
  address[] public strategyList;

  constructor() public {
  }

  function initializeFund(address _governance, 
  address _underlying,
  string memory _name,
  string memory _symbol
  ) public initializer {

    ERC20Upgradeable.__ERC20_init(
      _name,
      _symbol
    );

    __ReentrancyGuard_init();
    
    Governable.initializeGovernance(
      _governance
    );

    uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
    
    FundStorage.initializeFundStorage(
      _underlying,
      underlyingUnit,
      _governance,   // fund manager is initialized as governance
      _governance        // rewards contract is initialized as governance
    );
  }

  modifier onlyFundManagerOrGovernance() {
    require((_governance() == msg.sender) || (_fundManager() == msg.sender), "Not governance nor fund manager");
    _;
  }

  modifier whenDepositsNotPaused() {
    require(!_depositsPaused(), "Deposits are paused");
    _;
  }

  function fundManager() external view returns(address) {
    return _fundManager();
  }

  function underlying() external view override returns(address) {
    return _underlying();
  }

  function underlyingUnit() external view returns(uint256) {
    return _underlyingUnit();
  }

  function getStrategyCount() internal view returns(uint256 strategyCount) {
    return strategyList.length;
  }

  modifier whenStrategyDefined() {
    require(getStrategyCount() > 0, "Strategies must be defined");
    _;
  }

  function getStrategyList() public view returns (address[] memory listOfStrategies) { 
    return strategyList; 
  }

  function getStrategy(address strategy) public view returns (StrategyParams memory strategyDetail) { 
    return strategies[strategy]; 
  }

  /*
  * Returns the cash balance across all users in this fund.
  */
  function underlyingBalanceInFund() internal view returns (uint256) {
    return IERC20(_underlying()).balanceOf(address(this));
  }

  /* Returns the current underlying (e.g., DAI's) balance together with
   * the invested amount (if DAI is invested elsewhere by the strategy).
  */
  function underlyingBalanceWithInvestment() internal view returns (uint256) {
    uint256 underlyingBalance = underlyingBalanceInFund();
    if (getStrategyCount() == 0) {
      // initial state, when not set
      return underlyingBalance;
    }
    for (uint256 i=0; i<getStrategyCount(); i++) {
      underlyingBalance = underlyingBalance.add(IStrategy(strategyList[i]).investedUnderlyingBalance());
    }
    return underlyingBalance;
  }

  function getPricePerFullShare() public override view returns (uint256) {
    return totalSupply() == 0
        ? _underlyingUnit()
        : _underlyingUnit().mul(underlyingBalanceWithInvestment()).div(totalSupply());
  }

  /* get the user's share (in underlying)
  */
  function underlyingBalanceWithInvestmentForHolder(address holder) view external override returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return underlyingBalanceWithInvestment()
        .mul(balanceOf(holder))
        .div(totalSupply());
  }

  function isActiveStrategy(address strategy) internal view returns(bool isActive) {
    return strategies[strategy].weightage > 0;
  }

  function addStrategy(address newStrategy, uint256 weightage, uint256 performanceFeeStrategy) external onlyFundManagerOrGovernance {
    require(newStrategy != ZERO_ADDRESS, "new newStrategy cannot be empty");
    require(IStrategy(newStrategy).fund() == address(this), "The strategy does not belong to this fund");
    require(isActiveStrategy(newStrategy) == false, "This strategy is already active in this fund");
    require(weightage > 0, "The weightage should be greater than 0");
    require(_totalWeightInStrategies().add(weightage) <= _maxInvestmentInStrategies(), "Total investment can't be above 90%");
    require(performanceFeeStrategy <= MAX_PERFORMANCE_FEE_STRATEGY, "Performance fee too high");
    
    strategies[newStrategy].weightage = weightage;
    _setTotalWeightInStrategies(_totalWeightInStrategies().add(weightage));
    strategies[newStrategy].activation = block.timestamp;
    strategies[newStrategy].indexInList = getStrategyCount();
    strategies[newStrategy].performanceFeeStrategy = performanceFeeStrategy;
    strategyList.push(newStrategy);

    IERC20(_underlying()).safeApprove(newStrategy, 0);
    IERC20(_underlying()).safeApprove(newStrategy, uint256(~0));
  }

  function removeStrategy(address activeStrategy) external onlyFundManagerOrGovernance {
    require(activeStrategy != ZERO_ADDRESS, "current strategy cannot be empty");
    require(isActiveStrategy(activeStrategy), "This strategy is not active in this fund");

    _setTotalWeightInStrategies(_totalWeightInStrategies().sub(strategies[activeStrategy].weightage));
    uint256 totalStrategies = getStrategyCount();
    for (uint256 i=strategies[activeStrategy].indexInList; i<totalStrategies-1; i++) {
      strategyList[i] = strategyList[i+1];
      strategies[strategyList[i]].indexInList = i;
    }
    strategyList.pop();
    delete strategies[activeStrategy];
    IERC20(_underlying()).safeApprove(activeStrategy, 0);
    IStrategy(activeStrategy).withdrawAllToFund();
  }

  function updateStrategyWeightage(address activeStrategy, uint256 newWeightage) external onlyFundManagerOrGovernance {
    require(activeStrategy != ZERO_ADDRESS, "current strategy cannot be empty");
    require(isActiveStrategy(activeStrategy), "This strategy is not active in this fund");
    require(newWeightage > 0, "The weightage should be greater than 0");
    require(_totalWeightInStrategies().sub(strategies[activeStrategy].weightage).add(newWeightage) <= _maxInvestmentInStrategies(), "Total investment can't be above 90%");

    _setTotalWeightInStrategies(_totalWeightInStrategies().sub(strategies[activeStrategy].weightage).add(newWeightage));
    strategies[activeStrategy].weightage = newWeightage;
    _setShouldRebalance(true);
  }
  
  function updateStrategyPerformanceFee(address activeStrategy, uint256 newPerformanceFeeStrategy) external onlyFundManagerOrGovernance {
    require(activeStrategy != ZERO_ADDRESS, "current strategy cannot be empty");
    require(isActiveStrategy(activeStrategy), "This strategy is not active in this fund");
    require(newPerformanceFeeStrategy <= MAX_PERFORMANCE_FEE_STRATEGY, "Performance fee too high");

    strategies[activeStrategy].performanceFeeStrategy = newPerformanceFeeStrategy;
  }

  function processFees() internal {
    uint256 profitTotal = 0;
    uint256 platformFee = (_totalInvested() * (block.timestamp - _lastHardworkTimestamp())).mul(_platformFee()).div(MAX_BPS).div(SECS_PER_YEAR);
    
    for (uint256 i=0; i<getStrategyCount(); i++) {
      address strategy = strategyList[i];
        
      uint256 profit = MathUpgradeable.max((IStrategy(strategy).investedUnderlyingBalance() - strategies[strategy].lastBalance), 0);
      uint256 strategyCreatorFee = 0;
      uint256 fundManagerFee = 0;
      
      if (profit > 0) {
        strategyCreatorFee = profit.mul(strategies[strategy].performanceFeeStrategy).div(MAX_BPS);
        if (strategyCreatorFee > 0) {
          IERC20(_underlying()).safeTransfer(IStrategy(strategy).creator(), strategyCreatorFee);
        }
        profitTotal = profitTotal.add(profit);
      }
      emit StrategyRewards(strategy, profit, strategyCreatorFee);
    }
    
    uint256 fundManagerFee = profitTotal.mul(_performanceFeeFund()).div(MAX_BPS);
    if (fundManagerFee > 0) {
      address fundManagerRewards = (_fundManager() == governance()) ? _rewards() : _fundManager();
      IERC20(_underlying()).safeTransfer(fundManagerRewards, fundManagerFee);
      emit FundManagerRewards(profitTotal, fundManagerFee);
    }
    if (platformFee > 0) {
      IERC20(_underlying()).safeTransfer(_rewards(), platformFee);
      emit PlatformRewards(_totalInvested(), block.timestamp - _lastHardworkTimestamp(), platformFee);
    }
  }

  /**
  * Chooses the best strategy and re-invests. If the strategy did not change, it just calls
  * doHardWork on the current strategy. Call this through controller to claim hard rewards.
  */
  function doHardWork() whenStrategyDefined onlyFundManagerOrGovernance external {
    if (_lastHardworkTimestamp() > 0) {
      processFees();
    }
    // ensure that new funds are invested too

    if (_shouldRebalance()) {
      rebalancedHardWork();
    }
    else {
      uint256 lastReserve = _totalAccounted() > 0 ? _totalAccounted().sub(_totalInvested()) : 0;
      uint256 availableAmountToInvest = underlyingBalanceInFund() > lastReserve ? underlyingBalanceInFund().sub(lastReserve) : 0;
      require(availableAmountToInvest > 0, 'Not enough to invest');
      _setTotalAccounted(_totalAccounted().add(availableAmountToInvest));
      for (uint256 i=0; i<getStrategyCount(); i++) { 
        address strategy = strategyList[i];
        uint256 availableAmountForStrategy = availableAmountToInvest.mul(strategies[strategy].weightage).div(MAX_BPS);
        if (availableAmountForStrategy > 0) {
          IERC20(_underlying()).safeTransfer(strategy, availableAmountForStrategy);
          _setTotalInvested(_totalInvested().add(availableAmountForStrategy));
          emit InvestInStrategy(strategy, availableAmountForStrategy);
        }
        
        IStrategy(strategy).doHardWork();
        
        strategies[strategy].lastBalance = IStrategy(strategy).investedUnderlyingBalance();
      }
    }
    _setLastHardworkTimestamp(block.timestamp);
  }

  /*
  * Should be used very carefully as this might incur huge gas cost.
  * Needed here as the weightage might divert from required weightages.
  */
  
  function rebalancedHardWork() internal {
    uint256 totalUnderlyingWithInvestment = underlyingBalanceWithInvestment();
    _setTotalAccounted(totalUnderlyingWithInvestment);
    uint256 totalInvested = 0;
    uint256[] memory toDeposit = new uint256[](getStrategyCount());
    
    for (uint256 i=0; i<getStrategyCount(); i++) {
      address strategy = strategyList[i];
      uint256 shouldBeInStrategy = totalUnderlyingWithInvestment.mul(strategies[strategy].weightage).div(MAX_BPS);
      totalInvested = totalInvested.add(shouldBeInStrategy);
      uint256 currentlyInStrategy = IStrategy(strategy).investedUnderlyingBalance();
      if (currentlyInStrategy > shouldBeInStrategy) {    // withdraw from strategy
        IStrategy(strategy).withdrawToFund(currentlyInStrategy.sub(shouldBeInStrategy));
      } else if (shouldBeInStrategy > currentlyInStrategy) {   // can not directly deposit here as there might not be enough balance before withdrawing from required strategies
        toDeposit[i] = shouldBeInStrategy.sub(currentlyInStrategy);
      }  
    }
    _setTotalInvested(totalInvested);

    for (uint256 i=0; i<getStrategyCount(); i++) {
      address strategy = strategyList[i];
      if (toDeposit[i] > 0) {
        IERC20(_underlying()).safeTransfer(strategy, toDeposit[i]);
        emit InvestInStrategy(strategy, toDeposit[i]);
      }
      IStrategy(strategy).doHardWork();
      
      strategies[strategy].lastBalance = IStrategy(strategy).investedUnderlyingBalance();
    }
  }

  function pauseDeposits(bool trigger) public onlyFundManagerOrGovernance {
    _setDepositsPaused(trigger);
  }

  /*
  * Allows for depositing the underlying asset in exchange for shares.
  * Approval is assumed.
  */
  function deposit(uint256 amount) external override nonReentrant whenDepositsNotPaused {
    _deposit(amount, msg.sender, msg.sender);
  }

  /*
  * Allows for depositing the underlying asset and shares assigned to the holder.
  * This facilitates depositing for someone else (e.g. using DepositHelper)
  */
  function depositFor(uint256 amount, address holder) external override nonReentrant whenDepositsNotPaused {
    _deposit(amount, msg.sender, holder);
  }

  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(amount > 0, "Cannot deposit 0");
    require(beneficiary != ZERO_ADDRESS, "holder must be defined");

    if(_depositLimit() > 0) { // if deposit limit is 0, then there is no deposit limit
      require(underlyingBalanceWithInvestment().add(amount) <= _depositLimit(), "Total deposit limit hit");
    }

    if(_depositLimitTxMax() > 0) { // if deposit limit is 0, then there is no deposit limit
      require(amount <= _depositLimitTxMax(), "Maximum transaction deposit limit hit");
    }

    if(_depositLimitTxMin() > 0) { // if deposit limit is 0, then there is no deposit limit
      require(amount >= _depositLimitTxMin(), "Minimum transaction deposit limit hit");
    }

    uint256 toMint = totalSupply() == 0
        ? amount
        : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
    _mint(beneficiary, toMint);

    IERC20(_underlying()).safeTransferFrom(sender, address(this), amount);
    emit Deposit(beneficiary, amount);
  }

  function withdraw(uint256 numberOfShares) external override nonReentrant {
    require(totalSupply() > 0, "Fund has no shares");
    require(numberOfShares > 0, "numberOfShares must be greater than 0");
    
    uint256 totalSupply = totalSupply();
    _burn(msg.sender, numberOfShares);

    uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
        .mul(numberOfShares)
        .div(totalSupply);

    if (underlyingAmountToWithdraw > underlyingBalanceInFund()) {
      uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInFund());
      for (uint256 i=0; i<getStrategyCount(); i++) {
        if (isActiveStrategy(strategyList[i])) {
          uint256 weightage = strategies[strategyList[i]].weightage;
          uint256 missingforStrategy = missing.mul(weightage).div(MAX_BPS);
          IStrategy(strategyList[i]).withdrawToFund(missingforStrategy);
        }
      }
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = MathUpgradeable.min(underlyingAmountToWithdraw, underlyingBalanceInFund());
    }

    uint256 withdrawalFee = underlyingAmountToWithdraw.mul(_withdrawalFee()).div(MAX_BPS);
    underlyingAmountToWithdraw = underlyingAmountToWithdraw.sub(withdrawalFee);

    IERC20(_underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);
    IERC20(_underlying()).safeTransfer(_rewards(), withdrawalFee);
    
    emit Withdraw(msg.sender, underlyingAmountToWithdraw, withdrawalFee);
  }

  function shouldUpgrade() external override view returns (bool, address) {
    return (
      true,
      address(this)
    );
  }

  function finalizeUpgrade() external override onlyGovernance {
  }

  function setFundManager(address newFundManager) external onlyFundManagerOrGovernance {
      _setFundManager(newFundManager);
  }

  function setRewards(address newRewards) external onlyGovernance {
      _setRewards(newRewards);
  }

  function setMaxInvestmentInStrategies(uint256 value) external onlyFundManagerOrGovernance {
    require(value < MAX_BPS, "Value greater than 100%");
    _setMaxInvestmentInStrategies(value);
  }

  // if limit == 0 then there is no deposit limit
  function setDepositLimit(uint256 limit) external onlyFundManagerOrGovernance {
    _setDepositLimit(limit);
  }

  function depositLimit() external view returns(uint256) {
    return _depositLimit();
  }

  // if limit == 0 then there is no deposit limit
  function setDepositLimitTxMax(uint256 limit) external onlyFundManagerOrGovernance {
    _setDepositLimitTxMax(limit);
  }

  function depositLimitTxMax() external view returns(uint256) {
    return _depositLimitTxMax();
  }

  // if limit == 0 then there is no deposit limit
  function setDepositLimitTxMin(uint256 limit) external onlyFundManagerOrGovernance {
    _setDepositLimitTxMin(limit);
  }

  function depositLimitTxMin() external view returns(uint256) {
    return _depositLimitTxMin();
  }

  function setPerformanceFeeFund(uint256 fee) external onlyFundManagerOrGovernance {
    require(fee <= MAX_PERFORMANCE_FEE_FUND, "Fee greater than max limit");
    _setPerformanceFeeFund(fee);
  }

  function performanceFeeFund() external view returns(uint256) {
    return _performanceFeeFund();
  }

  function setPlatformFee(uint256 fee) external onlyFundManagerOrGovernance {
    require(fee <= MAX_PLATFORM_FEE, "Fee greater than max limit");
    _setPlatformFee(fee);
  }

  function platformFee() external view returns(uint256) {
    return _platformFee();
  }

  function setWithdrawalFee(uint256 fee) external onlyFundManagerOrGovernance {
    require(fee <= MAX_WITHDRAWAL_FEE, "Fee greater than max limit");
    _setWithdrawalFee(fee);
  }

  function withdrawalFee() external view returns(uint256) {
    return _withdrawalFee();
  }

  // no tokens should ever be stored on this contract. Any tokens that are sent here by mistake are recoverable by governance
  function sweep(address _token, address _sweepTo) external onlyGovernance {
    require(_token != address(_underlying()), "can not sweep underlying");
      IERC20(_token).safeTransfer(_sweepTo, IERC20(_token).balanceOf(address(this)));
  }
}
