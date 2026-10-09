package redisx

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"

	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// releaseIfOwner deletes the lock only when it still holds our token, so a holder
// whose lock expired cannot release someone else's.
var releaseIfOwner = redis.NewScript(`
if redis.call('GET', KEYS[1]) == ARGV[1] then
  return redis.call('DEL', KEYS[1])
end
return 0
`)

// ErrLockHeld is returned when another holder owns the lock.
var ErrLockHeld = errors.New("lock held by another holder")

// Locker hands out short-lived distributed locks (SET NX PX).
type Locker struct {
	rdb redis.Cmdable
	ids idgen.Generator
}

// NewLocker returns a locker.
func NewLocker(rdb redis.Cmdable, ids idgen.Generator) *Locker { return &Locker{rdb: rdb, ids: ids} }

// Acquire takes the lock for ttl or returns ErrLockHeld. The returned release function
// is safe to call after the lock expired.
func (l *Locker) Acquire(ctx context.Context, key string, ttl time.Duration) (func(context.Context) error, error) {
	token := l.ids.New().String()
	ok, err := l.rdb.SetNX(ctx, key, token, ttl).Result()
	if err != nil {
		return nil, fmt.Errorf("acquire lock %s: %w", key, err)
	}
	if !ok {
		return nil, ErrLockHeld
	}
	return func(ctx context.Context) error {
		if err := releaseIfOwner.Run(ctx, l.rdb, []string{key}, token).Err(); err != nil {
			return fmt.Errorf("release lock %s: %w", key, err)
		}
		return nil
	}, nil
}
