package outbox

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// MaxAttempts is how often an event is tried before it is dead-lettered.
const MaxAttempts = 10

// Dispatcher delivers an event to its subscribers (eventbus.Bus).
type Dispatcher interface {
	Dispatch(ctx context.Context, env eventbus.Envelope) error
}

// Relay moves events from every module's outbox to the bus.
type Relay struct {
	db      db.Beginner
	bus     Dispatcher
	modules map[string]string
	clock   clock.Clock
	log     *slog.Logger
	batch   int
}

// NewRelay returns a relay over the given modules' outboxes.
func NewRelay(conn db.Beginner, bus Dispatcher, modules []string, clk clock.Clock, log *slog.Logger) (*Relay, error) {
	tables := map[string]string{}
	for _, m := range modules {
		t, err := table(m, "outbox")
		if err != nil {
			return nil, err
		}
		tables[m] = t
	}
	return &Relay{db: conn, bus: bus, modules: tables, clock: clk, log: log, batch: 100}, nil
}

// Run relays until ctx ends, pausing interval between empty passes.
func (r *Relay) Run(ctx context.Context, interval time.Duration) {
	t := time.NewTicker(interval)
	defer t.Stop()
	for {
		if _, err := r.RunOnce(ctx); err != nil {
			r.log.ErrorContext(ctx, "outbox relay pass failed", "error", err)
		}
		select {
		case <-ctx.Done():
			return
		case <-t.C:
		}
	}
}

// RunOnce relays one batch from each module and returns how many events it delivered.
func (r *Relay) RunOnce(ctx context.Context) (int, error) {
	total := 0
	for module, tbl := range r.modules {
		n := 0
		err := db.WithTx(ctx, r.db, func(tx pgx.Tx) error {
			var err error
			n, err = r.relayModule(ctx, tx, module, tbl)
			return err
		})
		if err != nil {
			return total, fmt.Errorf("relay %s: %w", module, err)
		}
		total += n
	}
	return total, nil
}

type pendingRow struct {
	env       eventbus.Envelope
	attempts  int
	notBefore time.Time
}

func (r *Relay) relayModule(ctx context.Context, tx pgx.Tx, module, tbl string) (int, error) {
	rows, err := r.pending(ctx, tx, module, tbl)
	if err != nil {
		return 0, err
	}
	now := r.clock.Now()
	blocked := map[string]bool{}
	delivered := 0
	for _, row := range rows {
		// An aggregate's events stay in order: once one waits, later ones wait too.
		if blocked[row.env.AggregateID] || row.notBefore.After(now) {
			blocked[row.env.AggregateID] = true
			continue
		}
		dispatchErr := r.bus.Dispatch(ctx, row.env)
		if err := r.record(ctx, tx, tbl, row, dispatchErr, now); err != nil {
			return delivered, err
		}
		if dispatchErr != nil {
			blocked[row.env.AggregateID] = true
			continue
		}
		delivered++
	}
	return delivered, nil
}

func (r *Relay) pending(ctx context.Context, tx pgx.Tx, module, tbl string) ([]pendingRow, error) {
	rows, err := tx.Query(ctx, "SELECT id, aggregate_id, event_name, payload, created_at, attempts, next_attempt_at FROM "+tbl+
		" WHERE published_at IS NULL AND NOT dead ORDER BY created_at, id LIMIT $1 FOR UPDATE SKIP LOCKED", r.batch)
	if err != nil {
		return nil, fmt.Errorf("select pending: %w", err)
	}
	return pgx.CollectRows(rows, func(row pgx.CollectableRow) (pendingRow, error) {
		p := pendingRow{env: eventbus.Envelope{Module: module}}
		err := row.Scan(&p.env.ID, &p.env.AggregateID, &p.env.Name, &p.env.Payload, &p.env.OccurredAt, &p.attempts, &p.notBefore)
		return p, err
	})
}

// record marks a delivered event published, or schedules a retry with exponential
// backoff (capped at 5 minutes) and dead-letters it after MaxAttempts.
func (r *Relay) record(ctx context.Context, tx pgx.Tx, tbl string, row pendingRow, dispatchErr error, now time.Time) error {
	var err error
	if dispatchErr == nil {
		_, err = tx.Exec(ctx, "UPDATE "+tbl+" SET published_at = $2, attempts = attempts + 1 WHERE id = $1", row.env.ID, now)
	} else {
		attempts := row.attempts + 1
		backoff := min(time.Duration(1<<min(attempts, 9))*time.Second, 5*time.Minute)
		r.log.WarnContext(ctx, "event delivery failed", "event", row.env.Name, "id", row.env.ID, "attempt", attempts, "error", dispatchErr)
		_, err = tx.Exec(ctx, "UPDATE "+tbl+" SET attempts = $2, next_attempt_at = $3, last_error = $4, dead = $5 WHERE id = $1",
			row.env.ID, attempts, now.Add(backoff), dispatchErr.Error(), attempts >= MaxAttempts)
	}
	if err != nil {
		return fmt.Errorf("record delivery of %s: %w", row.env.ID, err)
	}
	return nil
}
