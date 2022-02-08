from time import sleep
from scripts.helper_functions import get_account, get_contract
from brownie import FunLotto, network, config


def deploy_contract():
    account = get_account()
    lottery = FunLotto.deploy(
        get_contract("eth_usd_price_feed"),
        get_contract("vrf_coordinator"),
        get_contract("link_token"),
        config["networks"][network.show_active()]["fee"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": account},
    )
    print("Lottery contract deployed")
    return lottery


def start_lottery():
    account = get_account()
    if len(FunLotto) == 0:
        lottery = deploy_contract()
        print("deploying a contract now")
    else:
        lottery = FunLotto[-1]
        print("Using the deployed contract")
    tx = lottery.OpenLottery({"from": account})
    tx.wait(1)
    tx_event = tx.events[0]["lotteryId"]
    print(f"Lottery Id {tx_event} started")
    print(f"events so far {tx.events}")


def lottery_fee():
    account = get_account()
    if len(FunLotto) == 0:
        lottery = deploy_contract()
        print("deploying a contract now")
    else:
        lottery = FunLotto[-1]
        print("Using the deployed contract")
    fee = lottery.getLotteryFee()
    print(f"lottery fee to enter {fee}")


def enter_lottery():
    account = get_account()
    if len(FunLotto) == 0:
        lottery = deploy_contract()
        print("deploying a contract now")
    else:
        lottery = FunLotto[-1]
        print("Using the deployed contract")
    fee = lottery.getLotteryFee()
    print(f"lottery fee to enter {fee}")
    tx = lottery.enterLottery({"from": account, "value": fee + 10000000})
    tx.wait(1)
    # tx = lottery.enterLottery({"from": get_account(index=1), "value": fee + 10000000})
    # tx.wait(1)
    # tx = lottery.enterLottery({"from": get_account(index=2), "value": fee + 10000000})
    # tx.wait(1)
    print(f"joined the lottery {tx.events}")


def close_lottery():
    account = get_account()
    if len(FunLotto) == 0:
        lottery = deploy_contract()
        print("deploying a contract now")
    else:
        lottery = FunLotto[-1]
        print("Using the deployed contract")
    tx = lottery.closeLottery({"from": account})
    tx.wait(1)
    sleep(180)
    print(f"Events = {tx.events}")
    print(f"recent winner {lottery.recentWinner()}")


def transfer_linkTokens():
    account = get_account()
    linkToken = get_contract("link_token")
    if len(FunLotto) == 0:
        lottery = deploy_contract()
        print("deploying a contract now")
    else:
        lottery = FunLotto[-1]
        print("Using the deployed contract")
    tx = linkToken.transfer(lottery.address, 1000000000000000000, {"from": account})
    tx.wait(1)
    print("tokens tarsnferred")


def main():
    # deploy_contract()
    # lottery_fee()
    start_lottery()
    # enter_lottery()
    # transfer_linkTokens()
    # close_lottery()
