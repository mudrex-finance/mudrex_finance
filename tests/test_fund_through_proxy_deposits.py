#!/usr/bin/python3

import pytest, brownie

def test_pause_deposits(fund_through_proxy, accounts):
    fund_through_proxy.pauseDeposits(True, {'from': accounts[0]})
    
    with brownie.reverts("Deposits are paused"):
        fund_through_proxy.deposit(50, {'from': accounts[1]})

def test_deposit_without_approval(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 100, {'from': accounts[0]})
    
    with brownie.reverts("ERC20: transfer amount exceeds allowance"):
        fund_through_proxy.deposit(50, {'from': accounts[1]})

def test_deposit(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 100, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50, {'from': accounts[1]})
    fund_through_proxy.deposit(50, {'from': accounts[1]})
    
    assert fund_through_proxy.balanceOf(accounts[1]) == 50   ## zero shares initially, so same amount minted as deposit
    assert token.balanceOf(accounts[1]) == 50

def test_deposit_event_fires(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 100, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50, {'from': accounts[1]})
    tx = fund_through_proxy.deposit(50, {'from': accounts[1]})
    
    assert tx.events["Deposit"].values() == [accounts[1], 50]

def test_price_per_share_after_first_deposit(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 100, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50, {'from': accounts[1]})
    fund_through_proxy.deposit(50, {'from': accounts[1]})
    
    assert fund_through_proxy.getPricePerShare() == fund_through_proxy.underlyingUnit()
