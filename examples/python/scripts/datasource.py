from stockmq.data import DataSource, Timeframe, Param
from stockmq.rpc import RPCClient

import zmq
import msgpack
import time

with RPCClient("tcp://10.211.55.3:8004") as rpc:
    with DataSource(rpc, "SI", "SPBFUT", "SiU2", Timeframe.M1, stream=True) as ds:
        print(ds.df())

        with zmq.Context().socket(zmq.SUB).connect("tcp://10.211.55.3:8005") as skt:
            skt.subscribe(ds.key)
            while msg := msgpack.unpackb(skt.recv_multipart()[1]):
                print(msg)

with RPCClient("tcp://10.211.55.3:8004") as rpc:
    param = Param(rpc, "SPBFUT", "SiU2")
    print(param["LAST"])

with RPCClient("tcp://10.211.55.3:8004") as rpc:
    with DataSource(rpc, "SI", "SPBFUT", "SiU2", Timeframe.M1) as ds:
        print(ds.df())

        size = len(ds)
        print(ds[size-1])
        while True:
            s = len(ds)
            if s != size:
                print(ds[s - 1])
                size = s
                time.sleep(1.0)
                break




