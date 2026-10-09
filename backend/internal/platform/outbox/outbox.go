// Package outbox writes domain events in the same transaction as the change that caused
// them and relays them to subscribers at least once, in order per aggregate
// (PRD §9.3 rule 5).
package outbox

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// table returns the quoted "<module>"."<name>" for a module schema; quoting keeps the
// identifier safe even though module names only ever come from code.
func table(module, name string) string {
	return pgx.Identifier{module, name}.Sanitize()
}

// Writer appends events to a module's outbox inside a transaction.
type Writer struct {
	module string
	table  string
	ids    idgen.Generator
	clock  clock.Clock
}

// NewWriter returns the outbox writer for module.
func NewWriter(module string, ids idgen.Generator, clk clock.Clock) *Writer {
	return &Writer{module: module, table: table(module, "outbox"), ids: ids, clock: clk}
}

// Write stores e for aggregateID in tx.
func (w *Writer) Write(ctx context.Context, tx pgx.Tx, aggregateID string, e eventbus.Event) error {
	payload, err := json.Marshal(e)
	if err != nil {
		return fmt.Errorf("encode %s: %w", e.EventName(), err)
	}
	_, err = tx.Exec(ctx, "INSERT INTO "+w.table+" (id, aggregate_id, event_name, payload, created_at, next_attempt_at) VALUES ($1, $2, $3, $4, $5, $5)",
		w.ids.New(), aggregateID, e.EventName(), payload, w.clock.Now())
	if err != nil {
		return fmt.Errorf("write %s to %s outbox: %w", e.EventName(), w.module, err)
	}
	return nil
}
