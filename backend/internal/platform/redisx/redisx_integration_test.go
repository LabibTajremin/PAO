//go:build integration

package redisx_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestConnect(t *testing.T) {
	ctx := context.Background()
	if _, err := redisx.Connect(ctx, "nope://"); err == nil {
		t.Fatal("bad url accepted")
	}
	if _, err := redisx.Connect(ctx, "redis://127.0.0.1:1/0"); err == nil {
		t.Fatal("connected to nothing")
	}
	if k := redisx.NewKeys("dev").Key("otp", "+880"); k != "pao:dev:otp:+880" {
		t.Fatalf("key = %s", k)
	}
}

func TestRateLimiter_SlidingWindow(t *testing.T) {
	ctx := context.Background()
	rdb, keys := testkit.Redis(t)
	clk := clock.NewFake(time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC))
	l := redisx.NewRateLimiter(rdb, clk, idgen.V7{})
	key := keys.Key("rl", "otp", "phone")
	for i := 0; i < 3; i++ {
		if d, err := l.Allow(ctx, key, 3, 15*time.Minute); err != nil || !d.Allowed {
			t.Fatalf("hit %d: %+v %v", i, d, err)
		}
		clk.Advance(time.Minute)
	}
	d, err := l.Allow(ctx, key, 3, 15*time.Minute)
	if err != nil || d.Allowed || d.RetryAfter != 12*time.Minute {
		t.Fatalf("4th hit: %+v %v", d, err)
	}
	clk.Advance(12 * time.Minute)
	if d, _ := l.Allow(ctx, key, 3, 15*time.Minute); !d.Allowed {
		t.Fatal("oldest hit did not leave the window")
	}
	if _, err := redisx.NewRateLimiter(testkit.ClosedRedis(t), clk, idgen.V7{}).Allow(ctx, key, 1, time.Second); err == nil {
		t.Fatal("closed client reported success")
	}
}

func TestLocker_OnlyOneHolder(t *testing.T) {
	ctx := context.Background()
	rdb, keys := testkit.Redis(t)
	l := redisx.NewLocker(rdb, idgen.V7{})
	key := keys.Key("lock", "booking", "b1")
	release, err := l.Acquire(ctx, key, 10*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := l.Acquire(ctx, key, 10*time.Second); !errors.Is(err, redisx.ErrLockHeld) {
		t.Fatalf("second acquire: %v", err)
	}
	if err := release(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err := l.Acquire(ctx, key, 10*time.Second); err != nil {
		t.Fatalf("after release: %v", err)
	}
	if err := release(ctx); err != nil || rdb.Exists(ctx, key).Val() != 1 {
		t.Fatal("stale release removed the new holder's lock")
	}
	closed := redisx.NewLocker(testkit.ClosedRedis(t), idgen.V7{})
	if _, err := closed.Acquire(ctx, key, time.Second); err == nil {
		t.Fatal("closed client acquired")
	}
	_ = rdb.Del(ctx, key)
	release, _ = l.Acquire(ctx, key, time.Second)
	_ = rdb.Close()
	if err := release(ctx); err == nil {
		t.Fatal("release on a closed client succeeded")
	}
}

func TestIdempotencyStore_ReplaysFirstResponse(t *testing.T) {
	ctx := context.Background()
	rdb, keys := testkit.Redis(t)
	s := redisx.NewIdempotencyStore(rdb, time.Hour)
	key := keys.Key("idem", "u1", "k1")
	if _, reserved, err := s.Reserve(ctx, key, "h1"); err != nil || !reserved {
		t.Fatalf("first reserve: %v %v", reserved, err)
	}
	if rec, reserved, _ := s.Reserve(ctx, key, "h1"); reserved || rec.Done {
		t.Fatalf("in-flight replay: %+v", rec)
	}
	if err := s.Complete(ctx, key, redisx.IdempotencyRecord{RequestHash: "h1", Status: 201, Body: []byte(`{}`)}); err != nil {
		t.Fatal(err)
	}
	rec, reserved, err := s.Reserve(ctx, key, "h1")
	if err != nil || reserved || !rec.Done || rec.Status != 201 || string(rec.Body) != "{}" {
		t.Fatalf("replay: %+v %v", rec, err)
	}
	if err := s.Release(ctx, key); err != nil {
		t.Fatal(err)
	}
	if _, reserved, _ := s.Reserve(ctx, key, "h2"); !reserved {
		t.Fatal("released key not reusable")
	}
	_ = rdb.Set(ctx, key, "garbage", time.Hour)
	if _, _, err := s.Reserve(ctx, key, "h1"); err == nil {
		t.Fatal("garbage decoded")
	}
	closed := redisx.NewIdempotencyStore(testkit.ClosedRedis(t), time.Hour)
	if _, _, err := closed.Reserve(ctx, key, "h"); err == nil {
		t.Fatal("closed reserve")
	}
	if err := closed.Complete(ctx, key, redisx.IdempotencyRecord{}); err == nil {
		t.Fatal("closed complete")
	}
	if err := closed.Release(ctx, key); err == nil {
		t.Fatal("closed release")
	}
}

func TestDenylist(t *testing.T) {
	ctx := context.Background()
	rdb, keys := testkit.Redis(t)
	d := redisx.NewDenylist(rdb, keys)
	if err := d.Deny(ctx, "j1", time.Minute); err != nil {
		t.Fatal(err)
	}
	if err := d.Deny(ctx, "j2", 0); err != nil {
		t.Fatal(err)
	}
	if ok, err := d.IsDenied(ctx, "j1"); !ok || err != nil {
		t.Fatalf("j1: %v %v", ok, err)
	}
	if ok, _ := d.IsDenied(ctx, "j2"); ok {
		t.Fatal("expired token stored")
	}
	closed := redisx.NewDenylist(testkit.ClosedRedis(t), keys)
	if err := closed.Deny(ctx, "j", time.Minute); err == nil {
		t.Fatal("closed deny")
	}
	if _, err := closed.IsDenied(ctx, "j"); err == nil {
		t.Fatal("closed check")
	}
}

func TestCache(t *testing.T) {
	ctx := context.Background()
	rdb, keys := testkit.Redis(t)
	c := redisx.NewCache(rdb)
	k := keys.Key("cache", "x")
	if _, ok, err := c.Get(ctx, k); ok || err != nil {
		t.Fatal("empty cache hit")
	}
	if err := c.Set(ctx, k, []byte("v"), time.Minute); err != nil {
		t.Fatal(err)
	}
	if v, ok, _ := c.Get(ctx, k); !ok || string(v) != "v" {
		t.Fatal("cache miss")
	}
	if err := c.Delete(ctx, k); err != nil {
		t.Fatal(err)
	}
	if _, _, err := redisx.NewCache(testkit.ClosedRedis(t)).Get(ctx, k); err == nil {
		t.Fatal("closed cache")
	}
}
