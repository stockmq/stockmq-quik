package quik

import (
	"math"
	"time"
)

func (q *Quik) Test(payload interface{}) (interface{}, error) {
	r, err := CallTyped[interface{}](q, "stockmq_test", payload)
	if err != nil {
		return nil, err
	}

	return r, nil
}

func (q *Quik) Time() (time.Time, error) {
	ut, err := CallTyped[float64](q, "stockmq_time")
	if err != nil {
		return time.Time{}, err
	}
	sec, dec := math.Modf(ut)
	return time.Unix(int64(sec), int64(dec)), nil
}
