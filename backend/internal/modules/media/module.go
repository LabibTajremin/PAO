// Package media wires the media module.
package media

import (
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/media/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
)

// Deps are the shared services the module needs.
type Deps struct {
	Pool    *pgxpool.Pool
	Storage port.Storage
	Auditor port.Auditor
	Bucket  string
	Clock   clock.Clock
	IDs     idgen.Generator
}

// Module is the wired media module.
type Module struct {
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
}

// New wires the module.
func New(d Deps) *Module {
	svc := app.New(app.Deps{Repo: postgres.New(d.Pool, d.Clock), Storage: d.Storage, Auditor: d.Auditor, Bucket: d.Bucket, Clock: d.Clock, IDs: d.IDs})
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc)}
}

// RegisterJobs adds the daily orphan purge.
func (m *Module) RegisterJobs(r *jobs.Registry) {
	jobs.Register(r, inproc.NewPurgeWorker(m.Service))
	r.Daily(3, 30, inproc.PurgeArgs{})
}
