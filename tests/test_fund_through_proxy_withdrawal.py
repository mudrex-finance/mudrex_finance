#!/usr/bin/python3

import pytest, brownie

def test_withdrawal_without_any_deposit(fund_through_proxy, accounts):
    with brownie.reverts("Fund has no shares"):
        fund_through_proxy.withdraw(50, {'from': accounts[1]})

def test_withdrawal_without_any_deposit_from_account(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 100, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50, {'from': accounts[1]})
    fund_through_proxy.deposit(50, {'from': accounts[1]})
    with brownie.reverts('ERC20: burn amount exceeds balance'):
        fund_through_proxy.withdraw(50, {'from': accounts[2]})

def test_withdrawal_without_enough_shares(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 100, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50, {'from': accounts[1]})
    fund_through_proxy.deposit(50, {'from': accounts[1]})
    with brownie.reverts('ERC20: burn amount exceeds balance'):
        fund_through_proxy.withdraw(100, {'from': accounts[1]})

def test_withdrawal(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 100, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50, {'from': accounts[1]})
    fund_through_proxy.deposit(50, {'from': accounts[1]})
    
    assert fund_through_proxy.balanceOf(accounts[1]) == 50   ## zero shares initially, so same amount minted as deposit

    fund_through_proxy.withdraw(50, {'from': accounts[1]})

    assert fund_through_proxy.balanceOf(accounts[1]) == 0
    assert token.balanceOf(accounts[1]) == 100

def test_withdrawal_with_deposits_paused(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 100, {'from': accounts[0]})
    token.approve(fund_through_proxy, 50, {'from': accounts[1]})
    fund_through_proxy.deposit(50, {'from': accounts[1]})
    fund_through_proxy.pauseDeposits(True, {'from': accounts[0]})
    
    assert fund_through_proxy.balanceOf(accounts[1]) == 50   ## zero shares initially, so same amount minted as deposit

    fund_through_proxy.withdraw(50, {'from': accounts[1]})

    assert fund_through_proxy.balanceOf(accounts[1]) == 0
    assert token.balanceOf(accounts[1]) == 100

def test_withdrawal_with_withdrawal_fee(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 10000000, {'from': accounts[0]})
    intial_balance_for_governance = token.balanceOf(accounts[0])
    intial_balance_for_account = token.balanceOf(accounts[1])
    token.approve(fund_through_proxy, 5000000, {'from': accounts[1]})
    fund_through_proxy.deposit(5000000, {'from': accounts[1]})
    
    assert fund_through_proxy.balanceOf(accounts[1]) == 5000000   ## zero shares initially, so same amount minted as deposit
    
    fund_through_proxy.setWithdrawalFee(50, {'from': accounts[0]})

    fund_through_proxy.withdraw(5000000, {'from': accounts[1]})

    expected_fee = 50 * 5000000/10000

    assert fund_through_proxy.balanceOf(accounts[1]) == 0
    assert token.balanceOf(accounts[1]) == intial_balance_for_account - expected_fee
    assert token.balanceOf(accounts[0]) == intial_balance_for_governance + expected_fee

def test_withdrawal_event_fires(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 10000000, {'from': accounts[0]})
    token.approve(fund_through_proxy, 5000000, {'from': accounts[1]})
    fund_through_proxy.deposit(5000000, {'from': accounts[1]})
    
    fund_through_proxy.setWithdrawalFee(50, {'from': accounts[0]})

    tx = fund_through_proxy.withdraw(5000000, {'from': accounts[1]})

    expected_fee = 50 * 5000000/10000

    assert tx.events["Withdraw"].values() == [accounts[1], 5000000 - expected_fee, expected_fee]

def test_withdrawal_with_withdrawal_fee_and_changed_rewards(fund_through_proxy, accounts, token):
    token.mint(accounts[1], 10000000, {'from': accounts[0]})
    intial_balance_for_governance = token.balanceOf(accounts[0])
    intial_balance_for_account = token.balanceOf(accounts[1])
    token.approve(fund_through_proxy, 5000000, {'from': accounts[1]})
    fund_through_proxy.deposit(5000000, {'from': accounts[1]})
    
    assert fund_through_proxy.balanceOf(accounts[1]) == 5000000   ## zero shares initially, so same amount minted as deposit
    
    fund_through_proxy.setWithdrawalFee(50, {'from': accounts[0]})
    fund_through_proxy.setPlatformRewards(accounts[5], {'from': accounts[0]})

    fund_through_proxy.withdraw(5000000, {'from': accounts[1]})

    expected_fee = 50 * 5000000/10000

    assert fund_through_proxy.balanceOf(accounts[1]) == 0
    assert token.balanceOf(accounts[1]) == intial_balance_for_account - expected_fee
    assert token.balanceOf(accounts[0]) == intial_balance_for_governance
    assert token.balanceOf(accounts[5]) == expected_fee
