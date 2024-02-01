package main

import (
	"fmt"
	"sync"
	"time"

	"github.com/stockmq/stockmq-quik/examples/go/quik"
)

func info() {
	conn, _ := quik.NewQuik("tcp://10.211.55.3:8004")
	defer conn.Close()

	conn.Connect()

	fmt.Println(conn.IsConnected())
	fmt.Println(conn.GetScriptPath())
	fmt.Println(conn.Time())
}

func main() {
	info()

	var wg sync.WaitGroup

	t0 := time.Now()
	c0 := 0
	f0 := 100000
	for x := 0; x < 7; x++ {
		wg.Add(1)
		c0 += f0
		go func(id int) {
			qk, _ := quik.NewQuik("tcp://10.211.55.3:8004")

			defer wg.Done()
			defer qk.Close()

			qk.Connect()

			for i := 0; i < f0; i++ {
				qk.Test(i)
			}
		}(x)
	}
	wg.Wait()

	fmt.Println("RPS", float64(c0)/time.Since(t0).Seconds())
}
