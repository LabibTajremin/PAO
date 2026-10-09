// Package redisx provides the Redis client, the key naming scheme and the coordination
// primitives built on Redis: rate limiting, locks and idempotency
// (docs/build/02-architecture.md §4).
package redisx

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

// Connect parses a redis:// URL, connects and pings.
func Connect(ctx context.Context, url string) (*redis.Client, error) {
	opts, err := redis.ParseURL(url)
	if err != nil {
		return nil, fmt.Errorf("parse redis url: %w", err)
	}
	client := redis.NewClient(opts)
	if err := client.Ping(ctx).Err(); err != nil {
		_ = client.Close()
		return nil, fmt.Errorf("ping redis: %w", err)
	}
	return client, nil
}

// Keys builds keys under the "pao:{env}:" prefix so environments can share a server.
type Keys struct{ prefix string }

// NewKeys returns the key builder for an environment.
func NewKeys(env string) Keys { return Keys{prefix: "pao:" + env + ":"} }

// Key joins parts with ":" under the prefix, e.g. Key("otp", phone).
func (k Keys) Key(parts ...string) string { return k.prefix + strings.Join(parts, ":") }

// Denylist records revoked access-token IDs until they would have expired anyway
// (logout, ban, role change).
type Denylist struct {
	rdb  redis.Cmdable
	keys Keys
}

// NewDenylist returns a denylist.
func NewDenylist(rdb redis.Cmdable, keys Keys) *Denylist { return &Denylist{rdb: rdb, keys: keys} }

// Deny revokes jti for ttl (the token's remaining lifetime).
func (d *Denylist) Deny(ctx context.Context, jti string, ttl time.Duration) error {
	if ttl <= 0 {
		return nil
	}
	if err := d.rdb.Set(ctx, d.keys.Key("deny", "jti", jti), "1", ttl).Err(); err != nil {
		return fmt.Errorf("deny token: %w", err)
	}
	return nil
}

// IsDenied reports whether jti was revoked.
func (d *Denylist) IsDenied(ctx context.Context, jti string) (bool, error) {
	n, err := d.rdb.Exists(ctx, d.keys.Key("deny", "jti", jti)).Result()
	if err != nil {
		return false, fmt.Errorf("check denylist: %w", err)
	}
	return n == 1, nil
}
