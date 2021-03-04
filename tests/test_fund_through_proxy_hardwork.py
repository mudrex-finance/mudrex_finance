#!/usr/bin/python3

import pytest, brownie

def test_hard_work_single_strategy(fund_through_proxy, accounts, token, profit_strategy_10):
    token.mint(accounts[1], 100000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})

    tx = fund_through_proxy.doHardWork({'from': accounts[0]})
    profit_strategy_10.investAllUnderlying({'from': accounts[0]})

    expected_tvl = ((50/100 * 50000000) * (1 + 10/100)) + (50/100 * 50000000)
    expected_price_per_share = fund_through_proxy.underlyingUnit() * (((50/100 * 50000000) * (1 + 10/100)) + (50/100 * 50000000)) / 50000000

    assert profit_strategy_10.investedUnderlyingBalance() == (50/100 * 50000000) * (1 + 10/100)
    assert fund_through_proxy.getPricePerShare() == expected_price_per_share
    assert tx.events["HardWorkDone"].values() == [50000000, fund_through_proxy.underlyingUnit()]

def test_hard_work_multiple_strategies(fund_through_proxy, accounts, token, profit_strategy_10, profit_strategy_50):
    token.mint(accounts[1], 100000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_50, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_50, 2000, 500, {'from': accounts[0]})

    fund_through_proxy.doHardWork({'from': accounts[0]})
    profit_strategy_10.investAllUnderlying({'from': accounts[0]})
    profit_strategy_50.investAllUnderlying({'from': accounts[0]})

    assert profit_strategy_10.investedUnderlyingBalance() == (50/100 * 50000000) * (1 + 10/100)
    assert profit_strategy_50.investedUnderlyingBalance() == (20/100 * 50000000) * (1 + 50/100)
    assert fund_through_proxy.getPricePerShare() == fund_through_proxy.underlyingUnit() * (((50/100 * 50000000) * (1 + 10/100)) + ((20/100 * 50000000) * (1 + 50/100)) + (30/100 * 50000000)) / 50000000

def test_remove_strategy_after_hard_work_multiple_strategies(fund_through_proxy, accounts, token, profit_strategy_10, profit_strategy_50):
    token.mint(accounts[1], 100000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_50, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_50, 2000, 500, {'from': accounts[0]})

    fund_through_proxy.doHardWork({'from': accounts[0]})
    profit_strategy_10.investAllUnderlying({'from': accounts[0]})
    profit_strategy_50.investAllUnderlying({'from': accounts[0]})

    assert profit_strategy_10.investedUnderlyingBalance() == (50/100 * 50000000) * (1 + 10/100)
    assert profit_strategy_50.investedUnderlyingBalance() == (20/100 * 50000000) * (1 + 50/100)
    assert fund_through_proxy.getPricePerShare() == fund_through_proxy.underlyingUnit() * (((50/100 * 50000000) * (1 + 10/100)) + ((20/100 * 50000000) * (1 + 50/100)) + (30/100 * 50000000)) / 50000000

    fund_through_proxy.removeStrategy(profit_strategy_50, {'from': accounts[0]})
    assert profit_strategy_50.investedUnderlyingBalance() == 0

def test_hard_work_single_strategy_rewards_event_fires(fund_through_proxy, accounts, token, profit_strategy_10):
    token.mint(accounts[1], 100000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})

    tx = fund_through_proxy.doHardWork({'from': accounts[0]})
    profit_strategy_10.investAllUnderlying({'from': accounts[0]})

    assert profit_strategy_10.investedUnderlyingBalance() == (50/100 * 50000000) * (1 + 10/100)
    assert fund_through_proxy.getPricePerShare() == fund_through_proxy.underlyingUnit() * (((50/100 * 50000000) * (1 + 10/100)) + (50/100 * 50000000)) / 50000000
    # assert tx.events["StrategyRewards"].values() == [profit_strategy_10, 0, 0]  ## zero profit for first hard work

    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})
    
    tx = fund_through_proxy.doHardWork({'from': accounts[0]})
    expected_profit = (50/100 * 50000000) * (10/100)
    expected_strategy_creator_fee = expected_profit * (500/10000)
    assert tx.events["StrategyRewards"].values() == [profit_strategy_10, expected_profit, expected_strategy_creator_fee]

def test_hard_work_single_strategy_creator_fee_to_account(fund_through_proxy, accounts, token, profit_strategy_10):
    token.mint(accounts[1], 100000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})

    tx = fund_through_proxy.doHardWork({'from': accounts[0]})
    profit_strategy_10.investAllUnderlying({'from': accounts[0]})

    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    tx = fund_through_proxy.doHardWork({'from': accounts[0]})   ## zero profit for first hard work, run again to test
    expected_profit = (50/100 * 50000000) * (10/100)
    expected_strategy_creator_fee = expected_profit * (500/10000)
    assert token.balanceOf(accounts[0]) == expected_strategy_creator_fee

def test_hard_work_single_strategy_creator_fee_fund_fee_to_account(fund_through_proxy, accounts, token, profit_strategy_10):
    token.mint(accounts[1], 100000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    fund_through_proxy.setPerformanceFeeFund(500, {'from': accounts[0]})

    tx = fund_through_proxy.doHardWork({'from': accounts[0]})
    profit_strategy_10.investAllUnderlying({'from': accounts[0]})

    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    tx = fund_through_proxy.doHardWork({'from': accounts[0]})   ## zero profit for first hard work, run again to test
    expected_profit = (50/100 * 50000000) * (10/100)
    expected_strategy_creator_fee = expected_profit * (500/10000)
    expected_fund_performance_fee = (expected_profit - expected_strategy_creator_fee) * (500/10000)
    assert token.balanceOf(accounts[0]) == expected_strategy_creator_fee + expected_fund_performance_fee
    assert tx.events["FundManagerRewards"].values() == [expected_profit - expected_strategy_creator_fee, expected_fund_performance_fee]

def test_hard_work_single_strategy_creator_fee_fund_fee_platform_fee_to_account(fund_through_proxy, accounts, token, profit_strategy_10):
    token.mint(accounts[1], 100000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    fund_through_proxy.setPerformanceFeeFund(500, {'from': accounts[0]})
    fund_through_proxy.setPlatformFee(100, {'from': accounts[0]})

    tx = fund_through_proxy.doHardWork({'from': accounts[0]})
    profit_strategy_10.investAllUnderlying({'from': accounts[0]})

    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    tx = fund_through_proxy.doHardWork({'from': accounts[0]})   ## zero profit for first hard work, run again to test
    expected_profit = (50/100 * 50000000) * (10/100)
    expected_strategy_creator_fee = expected_profit * (500/10000)
    expected_fund_performance_fee = (expected_profit - expected_strategy_creator_fee) * (500/10000)
    expected_platform_fee = 0   ## TODO: Need to figure out a way to test this as block.timestamp doesn't increase much.
    assert token.balanceOf(accounts[0]) == expected_strategy_creator_fee + expected_fund_performance_fee + expected_platform_fee
    # assert tx.events["PlatformRewards"].values() == [50/100 * 50000000, 0, 0]


def test_hard_work_single_strategy_creator_fee_fund_fee_to_new_rewards_account(fund_through_proxy, accounts, token, profit_strategy_10):
    token.mint(accounts[1], 100000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    fund_through_proxy.setPerformanceFeeFund(500, {'from': accounts[0]})
    fund_through_proxy.setPlatformRewards(accounts[5], {'from': accounts[0]})

    tx = fund_through_proxy.doHardWork({'from': accounts[0]})
    profit_strategy_10.investAllUnderlying({'from': accounts[0]})

    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    tx = fund_through_proxy.doHardWork({'from': accounts[0]})   ## zero profit for first hard work, run again to test
    expected_profit = (50/100 * 50000000) * (10/100)
    expected_strategy_creator_fee = expected_profit * (500/10000)
    expected_fund_performance_fee = (expected_profit - expected_strategy_creator_fee) * (500/10000)
    assert token.balanceOf(accounts[0]) == expected_strategy_creator_fee
    assert token.balanceOf(accounts[5]) == expected_fund_performance_fee


def test_rebalance_single_strategy_weight_change(fund_through_proxy, accounts, token, profit_strategy_10):
    token.mint(accounts[1], 100000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})

    fund_through_proxy.doHardWork({'from': accounts[0]})
    # profit_strategy_10.investAllUnderlying({'from': accounts[0]})  // No profit for easy testing
    assert profit_strategy_10.investedUnderlyingBalance() == (50/100 * 50000000)
    
    fund_through_proxy.updateStrategyWeightage(profit_strategy_10, 6000, {'from': accounts[0]})
    fund_through_proxy.doHardWork({'from': accounts[0]})

    assert profit_strategy_10.investedUnderlyingBalance() == (60/100 * 50000000)


def test_rebalance_single_strategy_manual(fund_through_proxy, accounts, token, profit_strategy_10):
    token.mint(accounts[1], 100000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
    fund_through_proxy.deposit(50000000, {'from': accounts[1]})

    token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})

    fund_through_proxy.doHardWork({'from': accounts[0]})
    profit_strategy_10.investAllUnderlying({'from': accounts[0]})
    fund_through_proxy.setShouldRebalance(True, {'from': accounts[0]})

    assert profit_strategy_10.investedUnderlyingBalance() == (50/100 * (1 + 10/100) * 50000000)


# def test_rebalance_multiple_strategies(fund_through_proxy, accounts, token, profit_strategy_10, profit_strategy_50):
#     token.mint(accounts[1], 100000000, {'from': accounts[0]})
#     token.approve(fund_through_proxy, 50000000, {'from': accounts[1]})
#     fund_through_proxy.deposit(50000000, {'from': accounts[1]})

#     token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_10, {'from': accounts[0]})
#     fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
#     token.grantRole(brownie.web3.keccak(text="MINTER_ROLE"), profit_strategy_50, {'from': accounts[0]})
#     fund_through_proxy.addStrategy(profit_strategy_50, 2000, 500, {'from': accounts[0]})

#     fund_through_proxy.doHardWork({'from': accounts[0]})
#     # profit_strategy_10.investAllUnderlying({'from': accounts[0]})  // No profit for easy testing
#     fund_through_proxy.updateStrategyWeightage(profit_strategy_10, 7000, {'from': accounts[0]})
#     fund_through_proxy.updateStrategyWeightage(profit_strategy_50, 1000, {'from': accounts[0]})
#     fund_through_proxy.rebalance({'from': accounts[0]})

#     assert profit_strategy_10.investedUnderlyingBalance() == (70/100 * 50000000)
#     assert profit_strategy_50.investedUnderlyingBalance() == (10/100 * 50000000)
