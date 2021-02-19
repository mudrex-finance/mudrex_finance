#!/usr/bin/python3
import brownie


def test_sender_balance_decreases(accounts, fund_through_proxy):
    sender_balance = fund_through_proxy.balanceOf(accounts[0])
    amount = sender_balance // 4

    fund_through_proxy.transfer(accounts[1], amount, {'from': accounts[0]})

    assert fund_through_proxy.balanceOf(accounts[0]) == sender_balance - amount


def test_receiver_balance_increases(accounts, fund_through_proxy):
    receiver_balance = fund_through_proxy.balanceOf(accounts[1])
    amount = fund_through_proxy.balanceOf(accounts[0]) // 4

    fund_through_proxy.transfer(accounts[1], amount, {'from': accounts[0]})

    assert fund_through_proxy.balanceOf(accounts[1]) == receiver_balance + amount


def test_total_supply_not_affected(accounts, fund_through_proxy):
    total_supply = fund_through_proxy.totalSupply()
    amount = fund_through_proxy.balanceOf(accounts[0])

    fund_through_proxy.transfer(accounts[1], amount, {'from': accounts[0]})

    assert fund_through_proxy.totalSupply() == total_supply


def test_returns_true(accounts, fund_through_proxy):
    amount = fund_through_proxy.balanceOf(accounts[0])
    tx = fund_through_proxy.transfer(accounts[1], amount, {'from': accounts[0]})

    assert tx.return_value is True


def test_transfer_full_balance(accounts, fund_through_proxy):
    amount = fund_through_proxy.balanceOf(accounts[0])
    receiver_balance = fund_through_proxy.balanceOf(accounts[1])

    fund_through_proxy.transfer(accounts[1], amount, {'from': accounts[0]})

    assert fund_through_proxy.balanceOf(accounts[0]) == 0
    assert fund_through_proxy.balanceOf(accounts[1]) == receiver_balance + amount


def test_transfer_zero_funds(accounts, fund_through_proxy):
    sender_balance = fund_through_proxy.balanceOf(accounts[0])
    receiver_balance = fund_through_proxy.balanceOf(accounts[1])

    fund_through_proxy.transfer(accounts[1], 0, {'from': accounts[0]})

    assert fund_through_proxy.balanceOf(accounts[0]) == sender_balance
    assert fund_through_proxy.balanceOf(accounts[1]) == receiver_balance


def test_transfer_to_self(accounts, fund_through_proxy):
    sender_balance = fund_through_proxy.balanceOf(accounts[0])
    amount = sender_balance // 4

    fund_through_proxy.transfer(accounts[0], amount, {'from': accounts[0]})

    assert fund_through_proxy.balanceOf(accounts[0]) == sender_balance


def test_insufficient_balance(accounts, fund_through_proxy):
    balance = fund_through_proxy.balanceOf(accounts[0])

    with brownie.reverts():
        fund_through_proxy.transfer(accounts[1], balance + 1, {'from': accounts[0]})


def test_transfer_event_fires(accounts, fund_through_proxy):
    amount = fund_through_proxy.balanceOf(accounts[0])
    tx = fund_through_proxy.transfer(accounts[1], amount, {'from': accounts[0]})

    assert len(tx.events) == 1
    assert tx.events["Transfer"].values() == [accounts[0], accounts[1], amount]
