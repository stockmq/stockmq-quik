# StockMQ

StockMQ is a high-performance RPC library that uses MsgPack and ZeroMQ designed to use with QUIK (ARQA Technologies) trading terminal.

# Features

* Supports x64 architecture (QUIK 8.0 and above)
* Simple and fast RPC protocol
* Works on Apple Silicon (using Parallels/VMWare and x64 emulation)
* Compatible with Lua 5.3 and Lua 5.4
* Provides Pub-Sub support for callback processing

# Clients

Sample connectors available:

* [Go](/examples/golang/)
* [Java](/examples/java/)
* [Kotlin](/examples/kotlin/)
* [NodeJS](/examples/nodejs/)
* [Python](/examples/python/)

# Python API

High-Level API is available [here](https://github.com/stockmq/stockmq-quik-python).

```python
#!/usr/bin/env python3
import asyncio
import time

from stockmq.api import Quik
from stockmq.ns.tx import TimeInForce, Side

account = "ACCOUNT"
client = "CLIENT"
board = "TQBR"
ticker = "SBER"

async def main():
    with Quik("tcp://10.211.55.3:8004") as api:
        print(f"Quik version: {api.info.VERSION}")
        print(f"Is Connected: {api.is_connected}")

        # Create transaction to BUY and wait for completion
        t0 = time.time()
        tx = await api.tx.create_order(account, client, board, ticker, TimeInForce.DAY, Side.BUY, 265, 1)
        print(tx)
        print(tx.updated_ts - tx.created_ts)

        # Create transaction to cancel the order
        tx = await api.tx.cancel_order(account, client, board, ticker, tx.order_id, timeout=4.0)
        print(tx)
        print(tx.updated_ts - tx.created_ts)

        print(f"Time to create and cancel: {time.time()-t0}")

if __name__ == '__main__':
    asyncio.run(main())
```

# Protocol implementation

RPC uses Req-Rep pattern. Here is an example of the Python connector.

```
import zmq
import msgpack

from typing import Any


class RPCRuntimeError(Exception):
    pass


class RPCTimeoutError(Exception):
    pass


class RPCClient:
    RPC_OK = 'OK'

    def __init__(self, uri: str = 'tcp://127.0.0.1:8004', timeout: int = 100):
        self.timeout = timeout
        self.zmq_ctx = zmq.Context()
        self.zmq_skt = self.zmq_ctx.socket(zmq.REQ)
        self.zmq_skt.setsockopt(zmq.RCVTIMEO, timeout)
        self.zmq_skt.setsockopt(zmq.LINGER, 0)
        self.zmq_skt.connect(uri)

    def __enter__(self):
        return self

    def __exit__(self, *args: Any, **kwargs: Any):
        self.close()

    def call(self, method: str, *args: Any, timeout: None | int = None) -> Any:
        self.zmq_skt.send(msgpack.packb([method, *args]))
        if self.zmq_skt.poll(timeout or self.timeout) == zmq.POLLIN:
            s1, s2 = self.zmq_skt.recv_multipart()
            status = s1.decode()
            result = msgpack.unpackb(s2, strict_map_key=False)

            if status == self.RPC_OK:
                return result
            else:
                raise RPCRuntimeError(result)
        else:
            raise RPCTimeoutError()

    def close(self):
        self.zmq_skt.close()
        
if __name__ == "__main__":
    with RPCClient() as rpc:
        print(rpc.call("your_function", "arg1", 2, True))
```

# Installation

Make sure you have installed the [Microsoft C/C++ libraries](https://aka.ms/vs/17/release/vc_redist.x64.exe)

* Download and extract the latest release of stockmq-quik-connector from [Releases](https://github.com/stockmq/stockmq-quik/releases)
* Load quik.lua script

# Configuration

The connector opens two sockets (Req-Rep for RPC and Pub-Sub for callback processing).
By default callbacks are disabled (with exception of DataSources) because polling is much faster and doesn't require a separate thread or coroutine to handle incoming messages.

```
STOCKMQ_RPC_TIMEOUT = 10
STOCKMQ_RPC_URI = "tcp://0.0.0.0:8004"

STOCKMQ_PUB_ENABLED = false
STOCKMQ_PUB_URI = "tcp://0.0.0.0:8005"
```

# Building

Before you begin building the application, you must have the following prerequisites installed on your system

* [Visual Studio 2022 (C++ Desktop Development)](https://visualstudio.microsoft.com/downloads/)

```
cmake --build --preset ninja-vcpkg-release --config Release
```
