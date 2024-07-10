# StockMQ

StockMQ is a high-performance RPC library that uses MsgPack and ZeroMQ designed to use with QUIK (ARQA Technologies) trading terminal.

```
Request  -> msgpack([method, args...])
Response -> status, msgpack(payload)
```

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

Python:

```python
with RPCClient("tcp://127.0.0.1:8004") as rpc:
    res = rpc.call("getParamEx2", "TQBR", "SBER", "LAST")
    print(f"Result {res}")
```

Go:

```go
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
```

# Installation

Make sure you have installed the [Microsoft C/C++ libraries](https://aka.ms/vs/17/release/vc_redist.x64.exe)

* Download and extract the latest release of stockmq-quik-connector from [Releases](https://github.com/stockmq/stockmq-quik/releases)
* Load quik.lua script

# Configuration

The connector opens a socket on loopback interface. You can bind it to the physical address by changing the *STOCKMQ_RPC_URI* variable: 

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
