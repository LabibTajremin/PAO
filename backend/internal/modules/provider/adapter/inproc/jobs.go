package inproc

import (
	"context"

	"github.com/riverqueue/river"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/app"
)

// ReapArgs is the presence.reap_lost job: providers whose heartbeat lapsed go offline.
type ReapArgs struct{}

// Kind implements river.JobArgs.
func (ReapArgs) Kind() string { return "provider.reap_lost_presence" }

// ReapWorker runs ReapArgs.
type ReapWorker struct {
	river.WorkerDefaults[ReapArgs]
	svc *app.Service
}

// NewReapWorker returns the worker.
func NewReapWorker(svc *app.Service) *ReapWorker { return &ReapWorker{svc: svc} }

// Work implements river.Worker.
func (w *ReapWorker) Work(ctx context.Context, _ *river.Job[ReapArgs]) error {
	return w.svc.ReapLost(ctx)
}
