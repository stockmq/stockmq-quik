package quik

import (
	"math"
	"time"
)

func (q *Quik) Test(payload interface{}) interface{} {
	return Call[interface{}](q, "stockmq_test", payload)
}

func (q *Quik) Time() time.Time {
	sec, dec := math.Modf(Call[float64](q, "stockmq_time"))
	return time.Unix(int64(sec), int64(dec))
}

func (q *Quik) Repl(payload string) interface{} {
	return Call[interface{}](q, "stockmq_repl", payload)
}
