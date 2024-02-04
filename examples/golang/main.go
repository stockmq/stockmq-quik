package main

import (
	"fmt"
	"time"

	zmq "github.com/pebbe/zmq4"
	msgpack "github.com/vmihailenco/msgpack/v5"
)

const RPC_OK = "OK"

type RPCRuntimeError struct {
	message string
}

func (e *RPCRuntimeError) Error() string {
	return e.message
}

type RPCTimeoutError struct {
	message string
}

func (e *RPCTimeoutError) Error() string {
	return e.message
}

type RPCClient struct {
	uri     string
	timeout time.Duration
	zmqCtx  *zmq.Context
	zmqSkt  *zmq.Socket
}

func NewRPCClient(uri string, timeout int) (*RPCClient, error) {
	zmqCtx, err := zmq.NewContext()
	if err != nil {
		return nil, err
	}
	zmqSkt, err := zmqCtx.NewSocket(zmq.REQ)
	if err != nil {
		return nil, err
	}
	zmqSkt.SetRcvtimeo(time.Duration(timeout) * time.Millisecond)
	zmqSkt.SetLinger(0)
	err = zmqSkt.Connect(uri)
	if err != nil {
		return nil, err
	}
	return &RPCClient{
		uri:     uri,
		timeout: time.Duration(timeout) * time.Millisecond,
		zmqCtx:  zmqCtx,
		zmqSkt:  zmqSkt,
	}, nil
}

func (c *RPCClient) Call(method string, args ...interface{}) (interface{}, error) {
	packed, err := msgpack.Marshal(append([]interface{}{method}, args...))
	if err != nil {
		return nil, err
	}
	_, err = c.zmqSkt.SendBytes(packed, 0)
	if err != nil {
		return nil, err
	}
	poller := zmq.NewPoller()
	poller.Add(c.zmqSkt, zmq.POLLIN)
	polled, err := poller.Poll(c.timeout)
	if err != nil {
		return nil, err
	}
	if len(polled) == 1 {
		status, err := c.zmqSkt.Recv(0)
		if err != nil {
			return nil, err
		}
		result, err := c.zmqSkt.RecvBytes(0)
		if err != nil {
			return nil, err
		}
		if status == RPC_OK {
			var unpacked interface{}
			err = msgpack.Unmarshal(result, &unpacked)
			if err != nil {
				return nil, err
			}
			return unpacked, nil
		} else {
			return nil, &RPCRuntimeError{message: string(result)}
		}
	} else {
		return nil, &RPCTimeoutError{message: "Timeout error"}
	}
}

func (c *RPCClient) Close() error {
	if err := c.zmqSkt.Close(); err != nil {
		return err
	}
	return c.zmqCtx.Term()
}

func main() {
	fmt.Println("StockMQ Go Example")
	rpc, err := NewRPCClient("tcp://10.211.55.3:8004", 5000)
	if err != nil {
		panic(err)
	}
	defer rpc.Close()
	res, err := rpc.Call("getParamEx2", "TQBR", "SBER", "LAST")
	if err != nil {
		panic(err)
	}
	fmt.Printf("Result %v\n", res)
}
