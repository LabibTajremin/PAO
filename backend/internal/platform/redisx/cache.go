package redisx

import (
	"context"
	"errors"
	"time"

	"github.com/redis/go-redis/v9"
)

// Cache stores rebuildable values (rendered catalog trees, settings, dashboards).
type Cache struct{ rdb redis.Cmdable }

// NewCache returns a cache.
func NewCache(rdb redis.Cmdable) *Cache { return &Cache{rdb: rdb} }

// Get returns the value and whether it was present.
func (c *Cache) Get(ctx context.Context, key string) ([]byte, bool, error) {
	v, err := c.rdb.Get(ctx, key).Bytes()
	if errors.Is(err, redis.Nil) {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}
	return v, true, nil
}

// Set stores a value for ttl.
func (c *Cache) Set(ctx context.Context, key string, value []byte, ttl time.Duration) error {
	return c.rdb.Set(ctx, key, value, ttl).Err()
}

// Delete forgets a value.
func (c *Cache) Delete(ctx context.Context, key string) error { return c.rdb.Del(ctx, key).Err() }
