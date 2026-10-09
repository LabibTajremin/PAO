//go:build integration

package redis_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/redis"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestStores_FailuresAndStaleEntries(t *testing.T) {
	ctx := context.Background()
	rdb, keys := testkit.Redis(t)
	closed := testkit.ClosedRedis(t)
	if _, err := redis.NewCodes(closed).Get(ctx, "k"); err == nil {
		t.Error("codes on closed redis")
	}
	sessions := redis.NewSessions(rdb, keys)
	if _, err := redis.NewSessions(closed, keys).Get(ctx, uuid.New()); err == nil {
		t.Error("session on closed redis")
	}
	if _, err := redis.NewSessions(closed, keys).ListForAccount(ctx, uuid.New()); err == nil {
		t.Error("list on closed redis")
	}
	account := uuid.New()
	live := domain.Family{ID: uuid.New(), AccountID: account, AccessExp: time.Now()}
	if err := sessions.Save(ctx, live, time.Hour); err != nil {
		t.Fatal(err)
	}
	rdb.SAdd(ctx, keys.Key("sess", account.String()), uuid.NewString())
	got, err := sessions.ListForAccount(ctx, account)
	if err != nil || len(got) != 1 || got[0].ID != live.ID {
		t.Fatalf("stale entry not dropped: %v %v", got, err)
	}
	ch := redis.NewChallenges(rdb, keys)
	rdb.Set(ctx, keys.Key("mfa", "x"), "{", time.Minute)
	if _, err := ch.Get(ctx, "x"); err == nil {
		t.Error("garbage challenge decoded")
	}
	if _, err := redis.NewChallenges(closed, keys).Get(ctx, "x"); err == nil {
		t.Error("challenge on closed redis")
	}
}

func TestSessions_ListReportsBrokenFamily(t *testing.T) {
	ctx := context.Background()
	rdb, keys := testkit.Redis(t)
	account, family := uuid.New(), uuid.New()
	rdb.SAdd(ctx, keys.Key("sess", account.String()), family.String())
	rdb.Set(ctx, keys.Key("rt", family.String()), "not-a-hash", time.Minute)
	if _, err := redis.NewSessions(rdb, keys).ListForAccount(ctx, account); err == nil {
		t.Fatal("wrong key type ignored")
	}
}
