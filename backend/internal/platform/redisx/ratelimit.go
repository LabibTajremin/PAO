package redisx

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"

	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// slidingWindow atomically drops hits older than the window, then records this hit
// if the limit allows it. It returns {allowed, oldest hit in ms}.
var slidingWindow = redis.NewScript(`
local key, now, window, limit, member = KEYS[1], tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3]), ARGV[4]
redis.call('ZREMRANGEBYSCORE', key, '-inf', now - window)
if redis.call('ZCARD', key) < limit then
  redis.call('ZADD', key, now, member)
  redis.call('PEXPIRE', key, window)
  return {1, 0}
end
local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
return {0, tonumber(oldest[2])}
`)

// Decision is the outcome of a rate-limit check.
type Decision struct {
	Allowed bool
	// RetryAfter is how long until the oldest counted hit leaves the window.
	RetryAfter time.Duration
}

// RateLimiter is a sliding-window limiter: at most limit hits per window per key.
type RateLimiter struct {
	rdb   redis.Scripter
	clock clock.Clock
	ids   idgen.Generator
}

// NewRateLimiter returns a limiter using clk for "now", so tests control time.
func NewRateLimiter(rdb redis.Scripter, clk clock.Clock, ids idgen.Generator) *RateLimiter {
	return &RateLimiter{rdb: rdb, clock: clk, ids: ids}
}

// Allow records a hit on key if fewer than limit hits happened within window.
func (l *RateLimiter) Allow(ctx context.Context, key string, limit int, window time.Duration) (Decision, error) {
	now := l.clock.Now().UnixMilli()
	res, err := slidingWindow.Run(ctx, l.rdb, []string{key},
		now, window.Milliseconds(), limit, strconv.FormatInt(now, 10)+"-"+l.ids.New().String()).Int64Slice()
	if err != nil {
		return Decision{}, fmt.Errorf("rate limit %s: %w", key, err)
	}
	if res[0] == 1 {
		return Decision{Allowed: true}, nil
	}
	retry := time.Duration(res[1]+window.Milliseconds()-now) * time.Millisecond
	return Decision{RetryAfter: max(retry, time.Second)}, nil
}
