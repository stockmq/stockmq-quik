# StockMQ for QUIK

StockMQ is a high-performance RPC library that uses MsgPack and ZeroMQ designed to use with QUIK trading terminal.

On AMD Ryzen 5600x it performs 10000 RPS in average.

```
-- Configure LUA_CPATH
package.cpath = package.cpath .. ';' 
    .. getScriptPath() .. "\\lib\\?.dll"

-- Load C++ extension
require("StockMQ")

-- Global constants
STOCKMQ_ZMQ_REP = 4
STOCKMQ_ZMQ_PUB = 1

STOCKMQ_RPC_TIMEOUT = 10
STOCKMQ_RPC_URI = "tcp://0.0.0.0:8004"
STOCKMQ_PUB_URI = "tcp://0.0.0.0:8005"

-- Global variables
STOCKMQ_RUN = false
STOCKMQ_PUB = nil

-- Set global variable which is used by main() function
function OnInit(script_path)
    STOCKMQ_PUB = StockMQ.bind(STOCKMQ_PUB_URI, STOCKMQ_ZMQ_PUB)
    STOCKMQ_RUN = true
end

-- Callback called when the script is stopped
function OnStop(signal)
    STOCKMQ_RUN = false
    return STOCKMQ_RPC_TIMEOUT
end

-- Main function
function main()
    local rpc = StockMQ.bind(STOCKMQ_RPC_URI, STOCKMQ_ZMQ_REP)

    message("StockMQ is listening on "..STOCKMQ_RPC_URI, 1)

    while STOCKMQ_RUN do
        if rpc:process() ~= 0 then
            message("StockMQ Error: code " .. tostring(rpc:errno()), 1)
        end
    end
end
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

# Prerequisites

Before you begin building the application, you must have the following prerequisites installed on your system

* [Visual Studio 2022 (C++ Desktop Development)](https://visualstudio.microsoft.com/downloads/)

# Building

```
cmake --build --preset ninja-vcpkg-release --config Release
```
