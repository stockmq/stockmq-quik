import time

from stockmq.rpc import RPCClient
from collections import OrderedDict
from datetime import datetime
import pandas as pd

from typing import Any, NamedTuple

from stockmq.schema import Timeframe


class Param:
    def __init__(self, rpc: RPCClient, board: str, ticker: str):
        self.rpc = rpc
        self.board = board
        self.ticker = ticker

    def __getitem__(self, index):
        if r := self.rpc.call("getParamEx2", self.board, self.ticker, index):
            return r
        else:
            raise IndexError


class DataSource:
    def __init__(self, rpc: RPCClient, name: str, board: str, ticker: str, timeframe: Timeframe, stream: bool = False):
        self.rpc = rpc
        self.key = self.rpc.call("stockmq_ds_create", name, board, ticker, timeframe.value, stream)

    def __enter__(self):
        while len(self) == 0:
            time.sleep(0.05)
        return self

    def __exit__(self, *args: Any, **kwargs: Any):
        self.close()

    def __len__(self):
        return self.rpc.call("stockmq_ds_size", self.key)

    def __getitem__(self, index):
        if r := self.rpc.call("stockmq_ds_peek", self.key, index):
            return r
        else:
            raise IndexError

    def close(self) -> None:
        self.rpc.call("stockmq_ds_delete", self.key)

    def df(self) -> pd.DataFrame:
        columns = ['T', 'O', 'H', 'L', 'C', 'V']
        if len(self):
            df = pd.DataFrame.from_records(self).reindex(columns=columns).set_index('T')
            df.index = pd.to_datetime(df.index, unit='s', utc=True).tz_convert('Europe/Moscow')
            return df
        else:
            return pd.DataFrame(columns=columns).set_index('T')
