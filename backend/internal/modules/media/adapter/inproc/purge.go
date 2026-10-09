package inproc

import (
	"context"

	"github.com/riverqueue/river"

	"github.com/LabibTajremin/PAO/backend/internal/modules/media/app"
)

// PurgeArgs is the daily media.purge_orphans job (02-architecture §9).
type PurgeArgs struct{}

// Kind implements river.JobArgs.
func (PurgeArgs) Kind() string { return "media.purge_orphans" }

// PurgeWorker deletes uploads never attached to a record.
type PurgeWorker struct {
	river.WorkerDefaults[PurgeArgs]
	svc *app.Service
}

// NewPurgeWorker returns the worker.
func NewPurgeWorker(svc *app.Service) *PurgeWorker { return &PurgeWorker{svc: svc} }

// Work implements river.Worker.
func (w *PurgeWorker) Work(ctx context.Context, _ *river.Job[PurgeArgs]) error {
	_, err := w.svc.PurgeOrphans(ctx)
	return err
}
