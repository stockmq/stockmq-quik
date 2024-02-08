package main

import (
	"errors"
	"fmt"
	"log"
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

func (c *RPCClient) Call(method string, args ...interface{}) ([]byte, error) {
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
			return result, nil
		} else {
			var errstr string
			if err := msgpack.Unmarshal(result, &errstr); err != nil {
				return nil, errors.Join(err, &RPCRuntimeError{message: string(result)})
			}
			return nil, &RPCRuntimeError{message: string(result)}
		}
	} else {
		return nil, &RPCTimeoutError{message: "Timeout error"}
	}
}

func (c *RPCClient) CallWithResult(result interface{}, method string, args ...interface{}) error {
	bytes, err := c.Call(method, args...)
	if err != nil {
		return err
	}
	if result != nil {
		if err := msgpack.Unmarshal(bytes, result); err != nil {
			return err
		}
	}
	return nil
}

func (c *RPCClient) Close() error {
	if err := c.zmqSkt.Close(); err != nil {
		return err
	}
	return c.zmqCtx.Term()
}

func main() {
	fmt.Println("StockMQ Go Example")
	rpc, err := NewRPCClient("tcp://10.211.55.3:8004", 100)
	if err != nil {
		log.Fatalln(err)
	}
	defer rpc.Close()

	var res1 map[string]string
	bytes, err := rpc.Call("getParamEx2", "TQBR", "SBER", "LAST")
	if err != nil {
		log.Fatalln(err)
	}
	if err := msgpack.Unmarshal(bytes, &res1); err != nil {
		log.Fatalln(err)
	}
	fmt.Printf("Result %v\n", res1)

	var res2 map[string]string
	if err := rpc.CallWithResult(&res2, "getParamEx2", "TQBR", "SBER", "LAST"); err != nil {
		log.Fatalln(err)
	}
	fmt.Printf("Result %v\n", res2["param_value"])
}
