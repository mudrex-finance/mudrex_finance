#!/usr/bin/python3

import pytest, brownie

def test_upgrade_fund_from_non_governance_account(fund_proxy, accounts, fund):
    
    with brownie.reverts("Issue when finalizing the upgrade"):
        fund_proxy.upgrade(fund, {'from': accounts[1]})

def test_upgrade_fund(fund_proxy, accounts, fund_2):
    fund_proxy.upgrade(fund_2, {'from': accounts[0]})
    
    assert fund_proxy.implementation() == fund_2

def test_changed_deposit_limit_after_upgrade(fund_proxy, fund_through_proxy, accounts, fund_2):
    fund_through_proxy.setDepositLimit(10, {'from': accounts[0]})
    fund_proxy.upgrade(fund_2, {'from': accounts[0]})
    
    assert fund_through_proxy.depositLimit() == 10
