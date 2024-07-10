# StockMQ

StockMQ is a high-performance RPC library that uses MsgPack and ZeroMQ designed to use with QUIK (ARQA Technologies) trading terminal.

# Features

* Supports x64 architecture (QUIK 8.0 and above)
* Simple and fast RPC protocol
* Works on Apple Silicon (using Parallels/VMWare and x64 emulation)
* Compatible with Lua 5.3 and Lua 5.4

# Clients

Connectors available:

* [Go](/examples/golang/)
* [Java](/examples/java/)
* [Kotlin](/examples/kotlin/)
* [NodeJS](/examples/nodejs/)
* [Python](/examples/python/)


For example,

```go
func main() {
	fmt.Println("StockMQ Go Example")
	rpc, err := NewRPCClient(context.Background(), "tcp://127.0.0.1:8004")
	if err != nil {
		log.Fatalln(err)
	}
	defer rpc.Close()

	var res map[string]string
	if err := rpc.CallWithResult(&res, "getParamEx2", "TQBR", "SBER", "LAST"); err != nil {
		log.Fatalln(err)
	}
	fmt.Printf("Result %v\n", res)
}
```

Python version:

```python
if __name__ == "__main__":
    with RPCClient("tcp://127.0.0.1:8004") as rpc:
        res = rpc.call("getParamEx2", "TQBR", "SBER", "LAST")

    print("StockMQ Python Example")
    print(f"Result {res}")
```

# Protocol implementation

RPC uses Req-Rep pattern. Each request and response serialized with msgpack.

Request: msgpack([method, args...])

Response: status, msgpack(payload)

Here is an example of the Python connector.


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

The connector opens a socket on loopback interface. You can bind it to the physical address by changing the value: 

```
STOCKMQ_RPC_TIMEOUT = 10
STOCKMQ_RPC_URI = "tcp://0.0.0.0:8004"
```

# Building

Before you begin building the application, you must have the following prerequisites installed on your system

* [Visual Studio 2022 (C++ Desktop Development)](https://visualstudio.microsoft.com/downloads/)

```
cmake --build --preset ninja-vcpkg-release --config Release
```
