#!/usr/bin/python3

import pytest, brownie

def test_strategy_initialization(fund_through_proxy, profit_strategy_10, token):
    assert profit_strategy_10.fund() == fund_through_proxy
    assert profit_strategy_10.underlying() == token

def test_add_strategy_wrong_fund(fund_through_proxy, accounts, profit_strategy_10_fund_2):
    with brownie.reverts("The strategy does not belong to this fund"):
        fund_through_proxy.addStrategy(profit_strategy_10_fund_2, 5000, 500, {'from': accounts[0]})

def test_add_strategy_zero_weightage(fund_through_proxy, accounts, profit_strategy_10):
    with brownie.reverts("The weightage should be greater than 0"):
        fund_through_proxy.addStrategy(profit_strategy_10, 0, 500, {'from': accounts[0]})

def test_add_strategy_very_high_weightage(fund_through_proxy, accounts, profit_strategy_10):
    with brownie.reverts("Total investment can't be above 90%"):
        fund_through_proxy.addStrategy(profit_strategy_10, 9500, 500, {'from': accounts[0]})

def test_add_strategy_very_high_performance_fee(fund_through_proxy, accounts, profit_strategy_10):
    with brownie.reverts("Performance fee too high"):
        fund_through_proxy.addStrategy(profit_strategy_10, 5000, 5000, {'from': accounts[0]})

def test_add_strategy_first_strategy(fund_through_proxy, accounts, profit_strategy_10):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})

    assert fund_through_proxy.getStrategyList() == [profit_strategy_10]
    assert fund_through_proxy.getStrategy(profit_strategy_10)[0] == 5000
    assert fund_through_proxy.getStrategy(profit_strategy_10)[1] == 500

def test_add_strategy_add_same_strategy(fund_through_proxy, accounts, profit_strategy_10):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})

    with brownie.reverts("This strategy is already active in this fund"):
        fund_through_proxy.addStrategy(profit_strategy_10, 1000, 500, {'from': accounts[0]})

def test_add_strategy_two_strategies(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_50, 2000, 500, {'from': accounts[0]})

    assert fund_through_proxy.getStrategyList() == [profit_strategy_10, profit_strategy_50]
    assert fund_through_proxy.getStrategy(profit_strategy_10)[0] == 5000
    assert fund_through_proxy.getStrategy(profit_strategy_10)[1] == 500
    assert fund_through_proxy.getStrategy(profit_strategy_50)[0] == 2000
    assert fund_through_proxy.getStrategy(profit_strategy_50)[1] == 500

def test_remove_strategy_wrong_strategy(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    with brownie.reverts("This strategy is not active in this fund"):
        fund_through_proxy.removeStrategy(profit_strategy_50, {'from': accounts[0]})

def test_remove_strategy_single_strategy(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    fund_through_proxy.removeStrategy(profit_strategy_10, {'from': accounts[0]})

    assert fund_through_proxy.getStrategyList() == []

def test_remove_strategy_two_strategies(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_50, 2000, 500, {'from': accounts[0]})
    fund_through_proxy.removeStrategy(profit_strategy_10, {'from': accounts[0]})

    assert fund_through_proxy.getStrategyList() == [profit_strategy_50]


def test_remove_strategy_multiple_strategies(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50, profit_strategy_80):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_50, 2000, 500, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_80, 1000, 500, {'from': accounts[0]})
    fund_through_proxy.removeStrategy(profit_strategy_50, {'from': accounts[0]})

    assert fund_through_proxy.getStrategyList() == [profit_strategy_10, profit_strategy_80]


def test_add_strategy_after_remove_strategy_multiple_strategies(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50, profit_strategy_80):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_50, 2000, 500, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_80, 1000, 500, {'from': accounts[0]})
    fund_through_proxy.removeStrategy(profit_strategy_50, {'from': accounts[0]})
    fund_through_proxy.addStrategy(profit_strategy_50, 2000, 500, {'from': accounts[0]})

    assert fund_through_proxy.getStrategyList() == [profit_strategy_10, profit_strategy_80, profit_strategy_50]

def test_update_strategy_weightage_wrong_strategy(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    with brownie.reverts("This strategy is not active in this fund"):
        fund_through_proxy.updateStrategyWeightage(profit_strategy_50, 2000, {'from': accounts[0]})

def test_update_strategy_weightage_very_high_weightage(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    with brownie.reverts("Total investment can't be above 90%"):
        fund_through_proxy.updateStrategyWeightage(profit_strategy_10, 9500, {'from': accounts[0]})

def test_update_strategy_weightage(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    fund_through_proxy.updateStrategyWeightage(profit_strategy_10, 6000, {'from': accounts[0]})

    assert fund_through_proxy.getStrategy(profit_strategy_10)[0] == 6000

def test_update_strategy_performance_fee_wrong_strategy(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    with brownie.reverts("This strategy is not active in this fund"):
        fund_through_proxy.updateStrategyPerformanceFee(profit_strategy_50, 200, {'from': accounts[0]})

def test_update_strategy_performance_fee_very_high_performance_fee(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    with brownie.reverts("Performance fee too high"):
        fund_through_proxy.updateStrategyPerformanceFee(profit_strategy_10, 5000, {'from': accounts[0]})

def test_update_strategy_performance_fee(fund_through_proxy, accounts, profit_strategy_10, profit_strategy_50):
    fund_through_proxy.addStrategy(profit_strategy_10, 5000, 500, {'from': accounts[0]})
    fund_through_proxy.updateStrategyPerformanceFee(profit_strategy_10, 200, {'from': accounts[0]})

    assert fund_through_proxy.getStrategy(profit_strategy_10)[1] == 200