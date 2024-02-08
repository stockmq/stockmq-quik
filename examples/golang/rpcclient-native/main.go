package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"time"

	zmq4 "github.com/go-zeromq/zmq4"
	msgpack "github.com/vmihailenco/msgpack/v5"
)

const RPC_OK = "OK"

type RPCClient struct {
	uri    string
	zmqSkt zmq4.Socket
}

func NewRPCClient(ctx context.Context, uri string, opts ...zmq4.Option) (*RPCClient, error) {
	zmqSkt := zmq4.NewReq(ctx, opts...)
	if err := zmqSkt.Dial(uri); err != nil {
		return nil, err
	}

	return &RPCClient{
		uri:    uri,
		zmqSkt: zmqSkt,
	}, nil
}

func (c *RPCClient) Close() error {
	return c.zmqSkt.Close()
}

func (c *RPCClient) Call(method string, args ...interface{}) ([]byte, error) {
	packed, err := msgpack.Marshal(append([]interface{}{method}, args...))
	if err != nil {
		return nil, err
	}

	if err := c.zmqSkt.Send(zmq4.NewMsg(packed)); err != nil {
		return nil, err
	}

	msg, err := c.zmqSkt.Recv()
	if err != nil {
		return nil, err
	}

	status := string(msg.Frames[0])
	result := msg.Frames[1]

	if status == RPC_OK {
		return result, nil
	} else {
		var errstr string
		if err := msgpack.Unmarshal(result, &errstr); err != nil {
			return nil, err
		}
		return nil, errors.New(errstr)
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

func main() {
	fmt.Println("StockMQ Go Example")
	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()

	rpc, err := NewRPCClient(ctx, "tcp://10.211.55.3:8004")
	if err != nil {
		log.Fatalln(err)
	}
	defer rpc.Close()

	t0 := time.Now()
	r := 0
	c := 100000
	for i := 0; i < c; i++ {
		rpc.CallWithResult(&r, "stockmq_test", 1)
	}
	t1 := time.Since(t0)
	log.Printf("Seconds: %f, RPS: %f", t1.Seconds(), float64(c)/t1.Seconds())

	var res map[string]string
	if err := rpc.CallWithResult(&res, "getParamEx2", "TQBR", "SBER", "LAST"); err != nil {
		log.Fatalln(err)
	}
	fmt.Printf("Result %v\n", res)
}
