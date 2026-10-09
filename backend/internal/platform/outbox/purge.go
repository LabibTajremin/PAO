package outbox

import (
	"context"
	"fmt"
	"time"

	"github.com/riverqueue/river"

	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
)

// PurgeArgs is the daily job that deletes delivered outbox rows.
type PurgeArgs struct{}

// Kind implements river.JobArgs.
func (PurgeArgs) Kind() string { return "outbox.purge_published" }

// PurgeWorker deletes events delivered more than Retention ago; dead letters stay for
// inspection.
type PurgeWorker struct {
	river.WorkerDefaults[PurgeArgs]
	db        db.Querier
	tables    []string
	clock     clock.Clock
	retention time.Duration
}

// NewPurgeWorker returns the purge worker for the modules' outboxes.
func NewPurgeWorker(conn db.Querier, modules []string, clk clock.Clock, retention time.Duration) (*PurgeWorker, error) {
	w := &PurgeWorker{db: conn, clock: clk, retention: retention}
	for _, m := range modules {
		t, err := table(m, "outbox")
		if err != nil {
			return nil, err
		}
		w.tables = append(w.tables, t)
	}
	return w, nil
}

// Work implements river.Worker.
func (w *PurgeWorker) Work(ctx context.Context, _ *river.Job[PurgeArgs]) error {
	cutoff := w.clock.Now().Add(-w.retention)
	for _, t := range w.tables {
		if _, err := w.db.Exec(ctx, "DELETE FROM "+t+" WHERE published_at < $1", cutoff); err != nil {
			return fmt.Errorf("purge %s: %w", t, err)
		}
	}
	return nil
}
