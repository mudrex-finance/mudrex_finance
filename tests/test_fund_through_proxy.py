#!/usr/bin/python3

import pytest, brownie

fund_name = "Mudrex Generic Fund"
fund_symbol = "MDXGF"

def test_initialization(fund_through_proxy, accounts, token):
    assert fund_through_proxy.governance() == accounts[0]
    assert fund_through_proxy.underlying() == token
    assert fund_through_proxy.decimals() == 18
    assert fund_through_proxy.symbol() == fund_symbol
    assert fund_through_proxy.name() == fund_name
    assert fund_through_proxy.fundManager() == accounts[0]
    assert fund_through_proxy.depositLimit() == 0
    assert fund_through_proxy.depositLimitTxMax() == 0
    assert fund_through_proxy.depositLimitTxMin() == 0
    assert fund_through_proxy.performanceFeeFund() == 0
    assert fund_through_proxy.platformFee() == 0
    assert fund_through_proxy.withdrawalFee() == 0
    assert fund_through_proxy.getPricePerShare() == fund_through_proxy.underlyingUnit()
    assert fund_through_proxy.getStrategyList() == []

def test_set_fund_manager(fund_through_proxy, accounts):
    fund_through_proxy.setFundManager(accounts[1], {'from': accounts[0]})
    
    assert fund_through_proxy.fundManager() == accounts[1]

def test_set_fund_manager_with_fund_manager(fund_through_proxy, accounts):
    fund_through_proxy.setFundManager(accounts[1], {'from': accounts[0]})
    fund_through_proxy.setFundManager(accounts[2], {'from': accounts[1]})
    
    assert fund_through_proxy.fundManager() == accounts[2]

def test_set_fund_manager_with_random_account(fund_through_proxy, accounts):
    
    with brownie.reverts("Not governance nor fund manager"):
        fund_through_proxy.setFundManager(accounts[1], {'from': accounts[3]})

def test_set_deposit_limit(fund_through_proxy, accounts):
    fund_through_proxy.setDepositLimit(10, {'from': accounts[0]})
    
    assert fund_through_proxy.depositLimit() == 10

def test_set_deposit_limit_per_tx_max(fund_through_proxy, accounts):
    fund_through_proxy.setDepositLimitTxMax(10, {'from': accounts[0]})
    
    assert fund_through_proxy.depositLimitTxMax() == 10

def test_set_deposit_limit_per_tx_min(fund_through_proxy, accounts):
    fund_through_proxy.setDepositLimitTxMin(10, {'from': accounts[0]})
    
    assert fund_through_proxy.depositLimitTxMin() == 10

def test_set_performance_fee_fund(fund_through_proxy, accounts):
    fund_through_proxy.setPerformanceFeeFund(500, {'from': accounts[0]})
    
    assert fund_through_proxy.performanceFeeFund() == 500

def test_set_performance_fee_fund_greater_than_max(fund_through_proxy, accounts):
    with brownie.reverts("Fee greater than max limit"):
        fund_through_proxy.setPerformanceFeeFund(5000, {'from': accounts[0]})

def test_set_platform_fee(fund_through_proxy, accounts):
    fund_through_proxy.setPlatformFee(100, {'from': accounts[0]})
    
    assert fund_through_proxy.platformFee() == 100

def test_set_platform_fee_fund_greater_than_max(fund_through_proxy, accounts):
    with brownie.reverts("Fee greater than max limit"):
        fund_through_proxy.setPlatformFee(5000, {'from': accounts[0]})

def test_set_withdrawal_fee(fund_through_proxy, accounts):
    fund_through_proxy.setWithdrawalFee(50, {'from': accounts[0]})
    
    assert fund_through_proxy.withdrawalFee() == 50

def test_set_withdrawal_fee_fund_greater_than_max(fund_through_proxy, accounts):
    with brownie.reverts("Fee greater than max limit"):
        fund_through_proxy.setWithdrawalFee(5000, {'from': accounts[0]})
