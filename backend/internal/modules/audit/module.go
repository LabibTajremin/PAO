// Package audit wires the append-only audit module.
package audit

import (
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Module is the wired audit module.
type Module struct {
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
}

// New wires the module.
func New(pool *pgxpool.Pool, clk clock.Clock, ids idgen.Generator) *Module {
	svc := app.New(postgres.New(pool), clk, ids)
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc)}
}

// Subscribe registers the audit handlers on the bus (worker process). Entries carry the
// event ID, so redelivery cannot duplicate them.
func (m *Module) Subscribe(bus *eventbus.Bus) {
	for name, h := range m.Service.Handlers() {
		bus.Subscribe(name, "audit", h)
	}
}
