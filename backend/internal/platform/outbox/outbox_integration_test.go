//go:build integration

package outbox_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

type ping struct{ N int }

func (ping) EventName() string { return "test.Ping" }

type unencodable struct{ C chan int }

func (unencodable) EventName() string { return "test.Bad" }

func setup(t *testing.T) (*pgxpool.Pool, *outbox.Writer, *clock.Fake) {
	t.Helper()
	pool, err := db.Connect(context.Background(), testkit.MigratedDatabase(t))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	clk := clock.NewFake(time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC))
	return pool, outbox.NewWriter("booking", idgen.V7{}, clk), clk
}

func write(t *testing.T, pool *pgxpool.Pool, w *outbox.Writer, agg string, n int) {
	t.Helper()
	err := db.WithTx(context.Background(), pool, func(tx pgx.Tx) error { return w.Write(context.Background(), tx, agg, ping{N: n}) })
	if err != nil {
		t.Fatal(err)
	}
}

func TestRelay_DeliversExactlyOnceToIdempotentHandler(t *testing.T) {
	ctx := context.Background()
	pool, w, clk := setup(t)
	bus := eventbus.NewBus()
	var applied []int
	failOnce := true
	h := outbox.Idempotent(pool, "rating", "count", func(ctx context.Context, tx pgx.Tx, env eventbus.Envelope) error {
		e, _ := eventbus.Decode[ping](env)
		applied = append(applied, e.N)
		return nil
	})
	bus.Subscribe("test.Ping", "count", h)
	bus.Subscribe("test.Ping", "flaky", func(context.Context, eventbus.Envelope) error {
		if failOnce {
			failOnce = false
			return errors.New("transient")
		}
		return nil
	})
	write(t, pool, w, "b1", 1)
	write(t, pool, w, "b1", 2)
	write(t, pool, w, "b2", 3)
	relay := outbox.NewRelay(pool, bus, []string{"booking"}, clk, logx.Discard())
	if n, err := relay.RunOnce(ctx); err != nil || n != 1 {
		t.Fatalf("first pass delivered %d: %v", n, err)
	}
	if n, _ := relay.RunOnce(ctx); n != 0 {
		t.Fatalf("retry ran before its backoff: %d", n)
	}
	clk.Advance(3 * time.Second)
	if n, err := relay.RunOnce(ctx); err != nil || n != 2 {
		t.Fatalf("second pass delivered %d: %v", n, err)
	}
	if len(applied) != 3 || applied[0] != 1 || applied[1] != 3 || applied[2] != 2 {
		t.Fatalf("applied = %v (b1 order kept, b2 not blocked, no duplicate)", applied)
	}
}

func TestRelay_DeadLettersAfterMaxAttempts(t *testing.T) {
	ctx := context.Background()
	pool, w, clk := setup(t)
	bus := eventbus.NewBus()
	bus.Subscribe("test.Ping", "broken", func(context.Context, eventbus.Envelope) error { return errors.New("always") })
	write(t, pool, w, "b1", 1)
	relay := outbox.NewRelay(pool, bus, []string{"booking"}, clk, logx.Discard())
	for i := 0; i < outbox.MaxAttempts; i++ {
		_, _ = relay.RunOnce(ctx)
		clk.Advance(10 * time.Minute)
	}
	var dead bool
	var attempts int
	if err := pool.QueryRow(ctx, "SELECT dead, attempts FROM booking.outbox").Scan(&dead, &attempts); err != nil || !dead || attempts != outbox.MaxAttempts {
		t.Fatalf("dead=%v attempts=%d err=%v", dead, attempts, err)
	}
}

func TestRelay_RunStopsWithContextAndLogsFailures(t *testing.T) {
	pool, _, clk := setup(t)
	relay := outbox.NewRelay(pool, eventbus.NewBus(), []string{"booking"}, clk, logx.Discard())
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan struct{})
	go func() { relay.Run(ctx, time.Millisecond); close(done) }()
	cancel()
	<-done
	pool.Close()
	ctx2, cancel2 := context.WithCancel(context.Background())
	cancel2()
	relay.Run(ctx2, time.Millisecond)
	if _, err := relay.RunOnce(context.Background()); err == nil {
		t.Fatal("closed pool relayed")
	}
}

func TestOutbox_Errors(t *testing.T) {
	ctx := context.Background()
	pool, w, clk := setup(t)
	err := db.WithTx(ctx, pool, func(tx pgx.Tx) error { return w.Write(ctx, tx, "a", unencodable{}) })
	if err == nil {
		t.Fatal("unencodable event written")
	}
	missing := outbox.NewWriter("nosuchmodule", idgen.V7{}, clk)
	if err := db.WithTx(ctx, pool, func(tx pgx.Tx) error { return missing.Write(ctx, tx, "a", ping{}) }); err == nil {
		t.Fatal("write to a missing schema succeeded")
	}
	relay := outbox.NewRelay(pool, eventbus.NewBus(), []string{"nosuchmodule"}, clk, logx.Discard())
	if _, err := relay.RunOnce(ctx); err == nil {
		t.Fatal("relay over a missing schema succeeded")
	}
	h := outbox.Idempotent(pool, "nosuchmodule", "h", nil)
	if err := h(ctx, eventbus.Envelope{}); err == nil {
		t.Fatal("idempotent handler on a missing schema succeeded")
	}
}

func TestRelay_ReportsBookkeepingFailure(t *testing.T) {
	pool, w, clk := setup(t)
	write(t, pool, w, "b1", 1)
	ctx, cancel := context.WithCancel(context.Background())
	bus := eventbus.NewBus()
	bus.Subscribe("test.Ping", "cancels", func(context.Context, eventbus.Envelope) error { cancel(); return nil })
	relay := outbox.NewRelay(pool, bus, []string{"booking"}, clk, logx.Discard())
	if _, err := relay.RunOnce(ctx); err == nil {
		t.Fatal("failed bookkeeping reported success")
	}
}

func TestPurgeWorker_DeletesOldDeliveredEvents(t *testing.T) {
	ctx := context.Background()
	pool, w, clk := setup(t)
	write(t, pool, w, "b1", 1)
	write(t, pool, w, "b2", 2)
	if _, err := pool.Exec(ctx, "UPDATE booking.outbox SET published_at = $1 WHERE aggregate_id = 'b1'", clk.Now()); err != nil {
		t.Fatal(err)
	}
	clk.Advance(8 * 24 * time.Hour)
	purge := outbox.NewPurgeWorker(pool, []string{"booking"}, clk, 7*24*time.Hour)
	if err := purge.Work(ctx, nil); err != nil {
		t.Fatal(err)
	}
	var left int
	_ = pool.QueryRow(ctx, "SELECT count(*) FROM booking.outbox").Scan(&left)
	if left != 1 || (outbox.PurgeArgs{}).Kind() != "outbox.purge_published" {
		t.Fatalf("rows left = %d", left)
	}
	missing := outbox.NewPurgeWorker(pool, []string{"nosuchmodule"}, clk, time.Hour)
	if err := missing.Work(ctx, nil); err == nil {
		t.Fatal("purge of a missing schema succeeded")
	}
}
