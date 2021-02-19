#!/usr/bin/python3

import pytest, brownie

def test_initialization(governable, accounts):
    assert governable.governance() == accounts[1]

def test_update_governance_from_non_governance_account(governable, accounts):
    
    with brownie.reverts():
        governable.updateGovernance(accounts[2], {'from': accounts[0]})

def test_update_governance_accept_from_wrong_account(governable, accounts):
    governable.updateGovernance(accounts[2], {'from': accounts[1]})
    
    with brownie.reverts():
        governable.acceptGovernance({'from': accounts[0]})

def test_update_governance_and_accept(governable, accounts):
    governable.updateGovernance(accounts[2], {'from': accounts[1]})
    governable.acceptGovernance({'from': accounts[2]})
    
    assert governable.governance() == accounts[2]

def test_accept_governance_event_fires(governable, accounts):
    governable.updateGovernance(accounts[2], {'from': accounts[1]})
    tx = governable.acceptGovernance({'from': accounts[2]})

    assert len(tx.events) == 1
    assert tx.events["GovernanceUpdated"].values() == [accounts[2]]
