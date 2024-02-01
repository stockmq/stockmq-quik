import time
import asyncio

from enum import Enum
from datetime import datetime
from pydantic import BaseModel
from typing import Any
from typing_extensions import Self

from stockmq.rpc import RPCClient


class TxTimeoutError(Exception):
    pass


class TxRejectedError(Exception):
    pass



class Action(str, Enum):
    NEW_ORDER = "NEW_ORDER"
    NEW_STOP_ORDER = "NEW_STOP_ORDER"
    KILL_ORDER = "KILL_ORDER"
    KILL_STOP_ORDER = "KILL_STOP_ORDER"


class OrderType(str, Enum):
    LIMIT = 'L'
    MARKET = 'M'

class TimeInForce(str, Enum):
    FOK = "FILL_OR_KILL"
    IOC = "KILL_BALANCE"
    DAY = "PUT_IN_QUEUE"


class Side(str, Enum):
    BUY = 'B'
    SELL = 'S'


class TransactionState(str, Enum):
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"
    EXECUTED = "EXECUTED"


class Transaction(BaseModel):
    id: int
    action: Action
    board: str
    order_id: int
    created_ts: float
    updated_ts: float
    state: TransactionState
    message: str

class Order(BaseModel):
    id: int
    board: str


class QuikTable:
    def __init__(self, rpc: RPCClient, name: str):
        self.rpc = rpc
        self.name = name

    def __len__(self):
        return int(self.rpc.call("getNumberOf", self.name))

    def __getitem__(self, index):
        r = self.rpc.call("stockmq_get_item", self.name, index)
        if r is None:
            raise IndexError
        return r


class QuikLua:
    def __init__(self, rpc: RPCClient):
        self.rpc = rpc

    def __getattr__(self, item: Any) -> Any:
        def wrapper(*args, **kwargs) -> Any:
            return self.rpc.call(item, *args)
        return wrapper


class QuikInfo:
    def __init__(self, rpc: RPCClient):
        self.rpc = rpc

    @property
    def VERSION(self) -> Any:
        return self.rpc.call("getInfoParam", "VERSION")

    @property
    def TRADEDATE(self) -> Any:
        return self.rpc.call("getInfoParam", "TRADEDATE")

    @property
    def SERVERTIME(self) -> Any:
        return self.rpc.call("getInfoParam", "SERVERTIME")

    @property
    def LASTRECORDTIME(self) -> Any:
        return self.rpc.call("getInfoParam", "LASTRECORDTIME")

    @property
    def NUMRECORDS(self) -> Any:
        return self.rpc.call("getInfoParam", "NUMRECORDS")

    @property
    def LASTRECORD(self) -> Any:
        return self.rpc.call("getInfoParam", "LASTRECORD")

    @property
    def LATERECORD(self) -> Any:
        return self.rpc.call("getInfoParam", "LATERECORD")

    @property
    def CONNECTION(self) -> Any:
        return self.rpc.call("getInfoParam", "CONNECTION")

    @property
    def IPADDRESS(self) -> Any:
        return self.rpc.call("getInfoParam", "IPADDRESS")

    @property
    def IPPORT(self) -> Any:
        return self.rpc.call("getInfoParam", "IPPORT")

    @property
    def IPCOMMENT(self) -> Any:
        return self.rpc.call("getInfoParam", "IPCOMMENT")

    @property
    def SERVER(self) -> Any:
        return self.rpc.call("getInfoParam", "SERVER")

    @property
    def SESSIONID(self) -> Any:
        return self.rpc.call("getInfoParam", "SESSIONID")

    @property
    def USER(self) -> Any:
        return self.rpc.call("getInfoParam", "USER")

    @property
    def USERID(self) -> Any:
        return self.rpc.call("getInfoParam", "USERID")

    @property
    def ORG(self) -> Any:
        return self.rpc.call("getInfoParam", "ORG")

    @property
    def LOCALTIME(self) -> Any:
        return self.rpc.call("getInfoParam", "LOCALTIME")

    @property
    def CONNECTIONTIME(self) -> Any:
        return self.rpc.call("getInfoParam", "CONNECTIONTIME")

    @property
    def MESSAGESSENT(self) -> Any:
        return self.rpc.call("getInfoParam", "MESSAGESSENT")

    @property
    def ALLSENT(self) -> Any:
        return self.rpc.call("getInfoParam", "ALLSENT")

    @property
    def BYTESSENT(self) -> Any:
        return self.rpc.call("getInfoParam", "BYTESSENT")

    @property
    def BYTESPERSECSENT(self) -> Any:
        return self.rpc.call("getInfoParam", "BYTESPERSECSENT")

    @property
    def MESSAGESRECV(self) -> Any:
        return self.rpc.call("getInfoParam", "MESSAGESRECV")

    @property
    def BYTESRECV(self) -> Any:
        return self.rpc.call("getInfoParam", "BYTESRECV")

    @property
    def ALLRECV(self) -> Any:
        return self.rpc.call("getInfoParam", "ALLRECV")

    @property
    def BYTESPERSECRECV(self) -> Any:
        return self.rpc.call("getInfoParam", "BYTESPERSECRECV")

    @property
    def AVGSENT(self) -> Any:
        return self.rpc.call("getInfoParam", "AVGSENT")

    @property
    def AVGRECV(self) -> Any:
        return self.rpc.call("getInfoParam", "AVGRECV")

    @property
    def LASTPINGTIME(self) -> Any:
        return self.rpc.call("getInfoParam", "LASTPINGTIME")

    @property
    def LASTPINGDURATION(self) -> Any:
        return self.rpc.call("getInfoParam", "LASTPINGDURATION")

    @property
    def AVGPINGDURATION(self) -> Any:
        return self.rpc.call("getInfoParam", "AVGPINGDURATION")

    @property
    def MAXPINGTIME(self) -> Any:
        return self.rpc.call("getInfoParam", "MAXPINGTIME")

    @property
    def MAXPINGDURATION(self) -> Any:
        return self.rpc.call("getInfoParam", "MAXPINGDURATION")
    

class Quik(RPCClient):
    TX_SLEEP_TIMEOUT = 0.01

    @property
    def lua(self) -> QuikLua:
        return QuikLua(self)

    @property
    def info(self) -> QuikInfo:
        return QuikInfo(self)

    @property
    def script_path(self) -> str:
        return self.call("getScriptPath")

    @property
    def working_folder(self) -> str:
        return self.call("getWorkingFolder")

    @property
    def is_connected(self) -> bool:
        return self.call("isConnected")

    def message(self, message, icon_type=1) -> None:
        self.call("message", message, icon_type)

    def debug(self, message) -> None:
        self.call("PrintDbgStr", message)

    def test(self, *args: Any) -> Any:
        return self.call("stockmq_test", *args)

    @property
    def firms(self) -> Any:
        return QuikTable(self, "firms")

    @property
    def classes(self) -> Any:
        return QuikTable(self, "classes")

    @property
    def securities(self) -> Any:
        return QuikTable(self, "securities")

    @property
    def trade_accounts(self) -> Any:
        return QuikTable(self, "trade_accounts")

    @property
    def client_codes(self) -> Any:
        return QuikTable(self, "client_codes")

    @property
    def all_trades(self) -> Any:
        return QuikTable(self, "all_trades")

    @property
    def account_positions(self) -> Any:
        return QuikTable(self, "account_positions")

    @property
    def orders(self) -> Any:
        return QuikTable(self, "orders")

    @property
    def futures_client_holding(self) -> Any:
        return QuikTable(self, "futures_client_holding")

    @property
    def futures_client_limits(self) -> Any:
        return QuikTable(self, "futures_client_limits")

    @property
    def money_limits(self) -> Any:
        return QuikTable(self, "money_limits")

    @property
    def depo_limits(self) -> Any:
        return QuikTable(self, "depo_limits")

    @property
    def trades(self) -> Any:
        return QuikTable(self, "trades")

    @property
    def stop_orders(self) -> Any:
        return QuikTable(self, "stop_orders")

    @property
    def neg_deals(self) -> Any:
        return QuikTable(self, "neg_deals")

    @property
    def neg_trades(self) -> Any:
        return QuikTable(self, "neg_trades")

    @property
    def neg_deal_reports(self) -> Any:
        return QuikTable(self, "neg_deal_reports")

    @property
    def firm_holding(self) -> Any:
        return QuikTable(self, "firm_holding")

    @property
    def account_balance(self) -> Any:
        return QuikTable(self, "account_balance")

    @property
    def ccp_holdings(self) -> Any:
        return QuikTable(self, "ccp_holdings")

    @property
    def rm_holdings(self) -> Any:
        return QuikTable(self, "rm_holdings")

    def repl(self, s: str) -> Any:
        return self.call("stockmq_repl", s)

    def get_table(self, name: str) -> QuikTable:
        return QuikTable(self, name)

    def get_classes(self) -> Any:
        return filter(len, self.call("getClassesList").split(","))

    def get_class_info(self, class_name) -> Any:
        return self.call("getClassInfo", class_name)

    def get_class_securities(self, class_name) -> Any:
        return filter(len, self.call("getClassSecurities", class_name).split(","))

    def get_security_info(self, class_name, sec_name) -> Any:
        return self.call("getSecurityInfo", class_name, sec_name)

    async def wait_tx(self, tx: Transaction, timeout=1.0) -> Transaction:
        t0 = time.time()
        while True:
            if time.time() - t0 >= timeout:
                raise TxTimeoutError()
            elif tx.state == TransactionState.EXECUTED:
                return tx
            elif tx.state == TransactionState.REJECTED:
                print(tx)
                raise TxRejectedError(tx.message)
            elif tx.state == TransactionState.ACCEPTED:
                await asyncio.sleep(self.TX_SLEEP_TIMEOUT)
                tx = self.update_transaction(tx)
                print(tx)

    def create_order_tx(self, client: str, board: str, ticker: str, tif: TimeInForce, side: Side, price: float, quantity: int) -> Transaction:
        return Transaction(**self.call("stockmq_create_order", client, board, ticker, tif.value, side.value, price, quantity))

    def create_stop_order_tx(self, client: str, board: str, ticker: str, tif: TimeInForce, side: Side, price: float, stop_price: float, quantity: int) -> Transaction:
        return Transaction(**self.call("stockmq_create_simple_stop_order", client, board, ticker, tif.value, side.value, price, stop_price, quantity))

    def cancel_order_tx(self, client: str, board: str, ticker: str, order_id: int) -> Transaction:
        return Transaction(**self.call("stockmq_cancel_order", client, board, ticker, order_id))

    def cancel_stop_order_tx(self, client: str, board: str, ticker: str, order_id: int) -> Transaction:
        return Transaction(**self.call("stockmq_cancel_stop_order", client, board, ticker, order_id))

    def update_transaction(self, tx: Transaction) -> Transaction:
        return Transaction(**self.call("stockmq_update_tx", tx.dict()))

    async def create_order(self, client: str, board: str, ticker: str, tif: TimeInForce, side: Side, price: float, quantity: int, timeout: float = 1.0) -> Transaction:
        return await self.wait_tx(self.create_order_tx(client, board, ticker, tif, side, price, quantity), timeout)

    async def create_stop_order(self, client: str, board: str, ticker: str, tif: TimeInForce, side: Side, price: float, stop_price: float, quantity: int, timeout: float = 1.0) -> Transaction:
        return await self.wait_tx(self.create_stop_order_tx(client, board, ticker, tif, side, price, stop_price, quantity), timeout)

    async def cancel_order(self, client: str, board: str, ticker: str, order_id: int, timeout: float = 1.0) -> Transaction:
        return await self.wait_tx(self.cancel_order_tx(client, board, ticker, order_id), timeout)

    async def cancel_stop_order(self, client: str, board: str, ticker: str, order_id: int, timeout: float = 1.0) -> Transaction:
        return await self.wait_tx(self.cancel_stop_order_tx(client, board, ticker, order_id), timeout)
