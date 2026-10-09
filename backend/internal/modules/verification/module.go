// Package verification wires the verification module.
package verification

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	catalog "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/adapter/peers"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Deps are the shared services and peer contracts the module needs.
type Deps struct {
	Pool     *pgxpool.Pool
	Cipher   port.Cipher
	Clock    clock.Clock
	IDs      idgen.Generator
	Provider provider.ProviderService
	Media    media.MediaService
	Catalog  catalog.CatalogService
	Admin    admin.AdminService
}

// Module is the wired verification module.
type Module struct {
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
}

// New wires the module.
func New(d Deps) *Module {
	svc := app.New(app.Deps{Repo: postgres.New(d.Pool, outbox.NewWriter("verification", d.IDs, d.Clock), d.Clock),
		Providers: peers.Providers{Svc: d.Provider}, Media: peers.Media{Svc: d.Media}, Catalog: peers.Catalog{Svc: d.Catalog},
		Settings: peers.Settings{Svc: d.Admin}, Cipher: d.Cipher, Clock: d.Clock, IDs: d.IDs})
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc)}
}

// Subscribe re-reviews changed profile steps and blocks suspended or banned providers.
// Both handlers converge on the same state when an event is delivered twice.
func (m *Module) Subscribe(bus *eventbus.Bus) {
	bus.Subscribe(provider.EnrolmentStepSaved{}.EventName(), "verification", func(ctx context.Context, env eventbus.Envelope) error {
		e, err := eventbus.Decode[provider.EnrolmentStepSaved](env)
		if err != nil {
			return err
		}
		return m.Service.OnStepSaved(ctx, e.ProviderID, e.Step)
	})
	bus.Subscribe(identity.AccountStatusChanged{}.EventName(), "verification", func(ctx context.Context, env eventbus.Envelope) error {
		e, err := eventbus.Decode[identity.AccountStatusChanged](env)
		if err != nil {
			return err
		}
		return m.Service.OnAccountStatus(ctx, e.AccountID, string(e.To))
	})
}

// RegisterJobs adds the daily expiry and reminder jobs (Asia/Dhaka).
func (m *Module) RegisterJobs(r *jobs.Registry) {
	expire, remind := inproc.NewWorkers(m.Service)
	jobs.Register(r, expire)
	jobs.Register(r, remind)
	r.Daily(2, 0, inproc.ExpireArgs{})
	r.Daily(9, 0, inproc.RemindArgs{})
}
