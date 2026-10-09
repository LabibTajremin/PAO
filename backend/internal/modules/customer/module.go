// Package customer wires the customer module.
package customer

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/adapter/peers"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/app"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Deps are the shared services and peer contracts the module needs.
type Deps struct {
	Pool     *pgxpool.Pool
	Clock    clock.Clock
	IDs      idgen.Generator
	Media    media.MediaService
	Identity identity.IdentityService
	Admin    admin.AdminService
}

// Module is the wired customer module.
type Module struct {
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
	pool     *pgxpool.Pool
}

// New wires the module.
func New(d Deps) *Module {
	svc := app.New(app.Deps{Repo: postgres.New(d.Pool, outbox.NewWriter("customer", d.IDs, d.Clock)),
		Media: peers.Media{Svc: d.Media}, Accounts: peers.Accounts{Svc: d.Identity}, Area: peers.Area{Svc: d.Admin}, Clock: d.Clock, IDs: d.IDs})
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc), pool: d.Pool}
}

// Subscribe erases a customer's profile and addresses when their account is deleted
// (PRD §11). The erase and the processed-event mark commit together.
func (m *Module) Subscribe(bus *eventbus.Bus) {
	bus.Subscribe(identity.AccountDeleted{}.EventName(), "customer",
		outbox.Idempotent(m.pool, "customer", "erase_account", func(ctx context.Context, tx pgx.Tx, env eventbus.Envelope) error {
			e, err := eventbus.Decode[identity.AccountDeleted](env)
			if err != nil {
				return err
			}
			return postgres.Erase(ctx, tx, e.AccountID)
		}))
	for name, h := range postgres.CopyHandlers() {
		bus.Subscribe(name, "customer", outbox.Idempotent(m.pool, "customer", name, h))
	}
}
