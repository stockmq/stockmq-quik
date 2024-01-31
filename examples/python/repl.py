#!/usr/bin/env python3
import argparse
from stockmq.rpc import RPCClient
from stockmq.rpc import RPCRuntimeError


def main():
    parser = argparse.ArgumentParser(description='StockMQ REPL')
    parser.add_argument("uri", type=str, help="Connection URI")
    args = parser.parse_args()
    
    with RPCClient(uri=args.uri) as rpc:
        print("Type exit() to terminate the session")
        while True:
            try:
                x = input(">> ")
                print(rpc.call("stockmq_repl", x))
            except RPCRuntimeError as err:
                print(f"Runtime error: {err}")

            if x == "exit()":
                break


if __name__ == "__main__":
    main()
