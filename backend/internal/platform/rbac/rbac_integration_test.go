//go:build integration

package rbac_test

import (
	"context"
	"errors"
	"slices"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/platform/rbac"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

type fakeSource struct {
	grants map[string]rbac.Grants
	loads  int
	err    error
}

func (f *fakeSource) LoadGrants(_ context.Context, role string) (rbac.Grants, error) {
	f.loads++
	return f.grants[role], f.err
}

func TestChecker_CachesPerVersion(t *testing.T) {
	ctx := context.Background()
	rdb, keys := testkit.Redis(t)
	src := &fakeSource{grants: map[string]rbac.Grants{
		"customer": {Permissions: []string{"booking:create", "booking:read:own"}, Screens: []string{"C07"}},
		"provider": {Permissions: []string{"job:respond", "booking:read:own"}, Screens: []string{"M15"}},
		"empty":    {},
	}}
	c := rbac.NewChecker(rdb, keys, src)

	g, err := c.Grants(ctx, []string{"customer", "provider", "empty"})
	if err != nil || !slices.Equal(g.Permissions, []string{"booking:create", "booking:read:own", "job:respond"}) ||
		!slices.Equal(g.Screens, []string{"C07", "M15"}) {
		t.Fatalf("grants = %+v %v", g, err)
	}
	if ok, _ := c.Has(ctx, []string{"customer", "empty"}, "booking:create"); !ok || src.loads != 3 {
		t.Fatalf("cached read reloaded: loads = %d", src.loads)
	}
	if ok, _ := c.Has(ctx, []string{"customer"}, "job:respond"); ok {
		t.Fatal("customer may respond to jobs")
	}
	src.grants["customer"] = rbac.Grants{Permissions: []string{"job:respond"}}
	if v, err := c.BumpVersion(ctx); err != nil || v != 1 {
		t.Fatalf("bump: %d %v", v, err)
	}
	if ok, _ := c.Has(ctx, []string{"customer"}, "job:respond"); !ok {
		t.Fatal("bump did not invalidate the cache")
	}
}

func TestChecker_Errors(t *testing.T) {
	ctx := context.Background()
	rdb, keys := testkit.Redis(t)
	failing := rbac.NewChecker(rdb, keys, &fakeSource{err: errors.New("db down")})
	if _, err := failing.Has(ctx, []string{"customer"}, "x"); err == nil {
		t.Fatal("source error swallowed")
	}
	closed := rbac.NewChecker(testkit.ClosedRedis(t), keys, &fakeSource{})
	if _, err := closed.Grants(ctx, []string{"customer"}); err == nil {
		t.Fatal("redis error swallowed")
	}
	if _, err := closed.BumpVersion(ctx); err == nil {
		t.Fatal("bump on closed redis")
	}
	_ = rdb.Set(ctx, keys.Key("rbac", "version"), "x", 0)
	if _, err := rbac.NewChecker(rdb, keys, &fakeSource{}).Version(ctx); err == nil {
		t.Fatal("non-numeric version accepted")
	}
	_ = rdb.Set(ctx, keys.Key("rbac", "version"), "0", 0)
	_ = rdb.Set(ctx, keys.Key("rbac", "role", "r", "v0"), "string-not-set", 0)
	if _, err := rbac.NewChecker(rdb, keys, &fakeSource{}).Grants(ctx, []string{"r"}); err == nil {
		t.Fatal("wrong key type accepted")
	}
	_ = rdb.SAdd(ctx, keys.Key("rbac", "role", "s", "v0"), "p")
	_ = rdb.Set(ctx, keys.Key("rbac", "screens", "s", "v0"), "string-not-set", 0)
	if _, err := rbac.NewChecker(rdb, keys, &fakeSource{}).Grants(ctx, []string{"s"}); err == nil {
		t.Fatal("wrong screens key type accepted")
	}
}
