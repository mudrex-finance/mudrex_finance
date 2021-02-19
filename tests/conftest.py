#!/usr/bin/python3

import pytest, brownie


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    # perform a chain rewind after completing each test, to ensure proper isolation
    # https://eth-brownie.readthedocs.io/en/v1.10.3/tests-pytest-intro.html#isolation-fixtures
    pass

@pytest.fixture(scope="module")
def token(Token, accounts):
    return Token.deploy("Stable Token", "STAB", {'from': accounts[0]})

@pytest.fixture(scope="module")
def token_2(Token, accounts):
    return Token.deploy("Stable Token 2", "STAB2", {'from': accounts[0]})

@pytest.fixture(scope="module")
def fund(Fund, accounts):
    return Fund.deploy({'from': accounts[0]})

@pytest.fixture(scope="module")
def fund_2(Fund, accounts):
    return Fund.deploy({'from': accounts[0]})

@pytest.fixture(scope="module")
def governable(Governable, accounts):
    governance = Governable.deploy({'from': accounts[0]})
    governance.initializeGovernance(accounts[1], {'from': accounts[0]})
    return governance

@pytest.fixture(scope="module")
def fund_factory(FundFactory, accounts):
    fund_factory = FundFactory.deploy({'from': accounts[0]})
    return fund_factory

@pytest.fixture(scope="module")
def fund_proxy(fund_factory, fund, token, accounts):
    fund_name = "Mudrex Generic Fund"
    fund_symbol = "MDXGF"
    tx = fund_factory.createFund(fund, token, fund_name, fund_symbol, {'from': accounts[0]})
    fund_proxy = brownie.FundProxy.at(tx.new_contracts[0])
    return fund_proxy

@pytest.fixture(scope="module")
def fund_through_proxy(fund_factory, fund, token, accounts):
    fund_name = "Mudrex Generic Fund"
    fund_symbol = "MDXGF"
    tx = fund_factory.createFund(fund, token, fund_name, fund_symbol, {'from': accounts[0]})
    fund_through_proxy = brownie.Fund.at(tx.new_contracts[0])
    return fund_through_proxy

@pytest.fixture(scope="module")
def profit_strategy_10(ProfitStrategy, fund_through_proxy, accounts):
    return ProfitStrategy.deploy(fund_through_proxy, 1000, {'from': accounts[0]})

@pytest.fixture(scope="module")
def profit_strategy_50(ProfitStrategy, fund_through_proxy, accounts):
    return ProfitStrategy.deploy(fund_through_proxy, 5000, {'from': accounts[0]})

@pytest.fixture(scope="module")
def profit_strategy_80(ProfitStrategy, fund_through_proxy, accounts):
    return ProfitStrategy.deploy(fund_through_proxy, 8000, {'from': accounts[0]})

@pytest.fixture(scope="module")
def profit_strategy_10_fund_2(ProfitStrategy, fund_2, accounts):
    return ProfitStrategy.deploy(fund_2, 1000, {'from': accounts[0]})