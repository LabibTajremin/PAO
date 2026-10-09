package inproc

import (
	"context"

	"github.com/riverqueue/river"

	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/app"
)

// ExpireArgs is the daily verification.expire_documents job (02-architecture §9).
type ExpireArgs struct{}

// Kind implements river.JobArgs.
func (ExpireArgs) Kind() string { return "verification.expire_documents" }

// RemindArgs is the daily verification.expiry_reminders job (P-11).
type RemindArgs struct{}

// Kind implements river.JobArgs.
func (RemindArgs) Kind() string { return "verification.expiry_reminders" }

// ExpireWorker runs ExpireArgs.
type ExpireWorker struct {
	river.WorkerDefaults[ExpireArgs]
	svc *app.Service
}

// Work implements river.Worker.
func (w *ExpireWorker) Work(ctx context.Context, _ *river.Job[ExpireArgs]) error {
	return w.svc.ExpireDocuments(ctx)
}

// RemindWorker runs RemindArgs.
type RemindWorker struct {
	river.WorkerDefaults[RemindArgs]
	svc *app.Service
}

// Work implements river.Worker.
func (w *RemindWorker) Work(ctx context.Context, _ *river.Job[RemindArgs]) error {
	return w.svc.RemindExpiring(ctx)
}

// NewWorkers returns both workers.
func NewWorkers(svc *app.Service) (*ExpireWorker, *RemindWorker) {
	return &ExpireWorker{svc: svc}, &RemindWorker{svc: svc}
}
