package quik

import (
	"errors"
	"log"

	"github.com/pebbe/zmq4"
	"github.com/vmihailenco/msgpack/v5"
)

type Quik struct {
	url     string
	zmq_ctx *zmq4.Context
	zmq_skt *zmq4.Socket
	zmq_pll *zmq4.Poller
}

func NewQuik(url string) (quik *Quik, err error) {
	quik = &Quik{}
	quik.url = url
	quik.zmq_ctx, err = zmq4.NewContext()
	if err != nil {
		return nil, err
	}

	quik.zmq_skt, err = quik.zmq_ctx.NewSocket(zmq4.REQ)
	if err != nil {
		return nil, err
	}
	quik.zmq_skt.SetLinger(0)

	quik.zmq_pll = zmq4.NewPoller()
	quik.zmq_pll.Add(quik.zmq_skt, zmq4.POLLIN)

	return quik, nil
}

func (q *Quik) Connect() error {
	return q.zmq_skt.Connect(q.url)
}

func (q *Quik) Close() error {
	return q.zmq_skt.Close()
}

func (q *Quik) Invoke(args ...interface{}) ([]byte, error) {
	b, err := msgpack.Marshal(args)
	if err != nil {
		log.Println(err)
	}
	q.zmq_skt.SendBytes(b, zmq4.DONTWAIT)

	sockets, _ := q.zmq_pll.Poll(-1)
	for _, socket := range sockets {
		switch s := socket.Socket; s {
		case q.zmq_skt:
			status, err := s.Recv(zmq4.SNDMORE)
			if err != nil {
				return nil, err
			}

			bytes, err := s.RecvBytes(zmq4.Flag(0))
			if err != nil {
				return nil, err
			}

			if status != "OK" {
				var errstr string
				if err := msgpack.Unmarshal(bytes, &errstr); err != nil {
					return bytes, err
				}

				return bytes, errors.New(errstr)
			}

			return bytes, nil
		}
	}

	return nil, errors.New("timeout error")
}

func CallTyped[T any](q *Quik, args ...interface{}) (T, error) {
	bytes, err := q.Invoke(args...)
	var result [1]T

	if err != nil {
		return result[0], err
	}

	if err := msgpack.Unmarshal(bytes, &result); err != nil {
		return result[0], err
	}

	return result[0], nil
}
