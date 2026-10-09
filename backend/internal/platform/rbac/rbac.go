// Package rbac answers "may these roles do this?" and "which screens may they see?" from
// a Redis cache keyed by the RBAC version, falling back to the identity module's tables
// through Source (docs/build/02-architecture.md §6).
package rbac

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"

	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// Grants are what one role allows.
type Grants struct {
	Permissions []string
	Screens     []string
}

// Source loads a role's grants from the system of record (identity tables).
type Source interface {
	LoadGrants(ctx context.Context, role string) (Grants, error)
}

// emptyMarker distinguishes "cached as empty" from "not cached".
const emptyMarker = "~"

// Checker caches grants per role and version for an hour.
type Checker struct {
	rdb  redis.Cmdable
	keys redisx.Keys
	src  Source
	ttl  time.Duration
}

// NewChecker returns a checker.
func NewChecker(rdb redis.Cmdable, keys redisx.Keys, src Source) *Checker {
	return &Checker{rdb: rdb, keys: keys, src: src, ttl: time.Hour}
}

// Version returns the current RBAC version (0 before the first change).
func (c *Checker) Version(ctx context.Context) (int64, error) {
	v, err := c.rdb.Get(ctx, c.keys.Key("rbac", "version")).Int64()
	if errors.Is(err, redis.Nil) {
		return 0, nil
	}
	if err != nil {
		return 0, fmt.Errorf("read rbac version: %w", err)
	}
	return v, nil
}

// BumpVersion invalidates every cached role after a role or permission change.
func (c *Checker) BumpVersion(ctx context.Context) (int64, error) {
	v, err := c.rdb.Incr(ctx, c.keys.Key("rbac", "version")).Result()
	if err != nil {
		return 0, fmt.Errorf("bump rbac version: %w", err)
	}
	return v, nil
}

// Grants returns the union of the roles' grants.
func (c *Checker) Grants(ctx context.Context, roles []string) (Grants, error) {
	version, err := c.Version(ctx)
	if err != nil {
		return Grants{}, err
	}
	var all Grants
	for _, role := range roles {
		g, err := c.roleGrants(ctx, role, version)
		if err != nil {
			return Grants{}, err
		}
		all.Permissions = append(all.Permissions, g.Permissions...)
		all.Screens = append(all.Screens, g.Screens...)
	}
	slices.Sort(all.Permissions)
	slices.Sort(all.Screens)
	return Grants{Permissions: slices.Compact(all.Permissions), Screens: slices.Compact(all.Screens)}, nil
}

// Has reports whether any of the roles grants permission.
func (c *Checker) Has(ctx context.Context, roles []string, permission string) (bool, error) {
	g, err := c.Grants(ctx, roles)
	if err != nil {
		return false, err
	}
	_, found := slices.BinarySearch(g.Permissions, permission)
	return found, nil
}

func (c *Checker) roleGrants(ctx context.Context, role string, version int64) (Grants, error) {
	v := "v" + strconv.FormatInt(version, 10)
	permKey, screenKey := c.keys.Key("rbac", "role", role, v), c.keys.Key("rbac", "screens", role, v)
	perms, err := c.rdb.SMembers(ctx, permKey).Result()
	if err != nil {
		return Grants{}, fmt.Errorf("read cached grants for %s: %w", role, err)
	}
	if len(perms) > 0 {
		screens, err := c.rdb.SMembers(ctx, screenKey).Result()
		if err != nil {
			return Grants{}, fmt.Errorf("read cached screens for %s: %w", role, err)
		}
		return Grants{Permissions: withoutMarker(perms), Screens: withoutMarker(screens)}, nil
	}
	g, err := c.src.LoadGrants(ctx, role)
	if err != nil {
		return Grants{}, fmt.Errorf("load grants for %s: %w", role, err)
	}
	c.cache(ctx, permKey, g.Permissions)
	c.cache(ctx, screenKey, g.Screens)
	return g, nil
}

// cache stores a set best-effort: a failed write only costs another database read.
func (c *Checker) cache(ctx context.Context, key string, members []string) {
	values := []any{emptyMarker}
	for _, m := range members {
		values = append(values, m)
	}
	pipe := c.rdb.TxPipeline()
	pipe.SAdd(ctx, key, values...)
	pipe.Expire(ctx, key, c.ttl)
	_, _ = pipe.Exec(ctx)
}

func withoutMarker(members []string) []string {
	return slices.DeleteFunc(members, func(m string) bool { return m == emptyMarker })
}
