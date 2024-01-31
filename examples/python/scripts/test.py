from stockmq.data import DataSource
from stockmq.rpc import RPCClient
from stockmq.schema import Timeframe

import timeit

def test():
    with RPCClient("tcp://10.211.55.3:8001") as rpc:
        with DataSource(rpc, "SI", "SPBFUT", "SiU2", Timeframe.M1) as ds:
            df = ds.df()
            print(df)

print(timeit.timeit(test, number=1))



