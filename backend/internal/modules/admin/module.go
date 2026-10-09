// Package admin wires the admin module.
package admin

import (
	"log/slog"

	"github.com/jackc/pgx/v5/pgxpool"
	goredis "github.com/redis/go-redis/v9"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/peers"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/app"
	audit "github.com/LabibTajremin/PAO/backend/internal/modules/audit/contract"
	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	catalog "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	customer "github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	rating "github.com/LabibTajremin/PAO/backend/internal/modules/rating/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// Deps are the shared services the module needs.
type Deps struct {
	Pool     *pgxpool.Pool
	Redis    goredis.Cmdable
	Keys     redisx.Keys
	Clock    clock.Clock
	IDs      idgen.Generator
	Log      *slog.Logger
	Media    media.MediaService
	Identity identity.IdentityService
}

// Module is the wired admin module.
type Module struct {
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
	repo     *postgres.Repository
	identity identity.IdentityService
}

// New wires the module.
func New(d Deps) *Module {
	repo := postgres.New(d.Pool, outbox.NewWriter("admin", d.IDs, d.Clock))
	svc := app.New(app.Deps{Repo: repo, Cache: redisx.NewCache(d.Redis), Keys: d.Keys, Clock: d.Clock, IDs: d.IDs, Log: d.Log,
		Media: peers.Media{Svc: d.Media}, Admins: peers.Admins{Svc: d.Identity}})
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc), repo: repo, identity: d.Identity}
}

// Late are the modules built after admin because they read its settings.
type Late struct {
	Booking      booking.BookingService
	Verification verification.VerificationService
	Provider     provider.ProviderService
	Customer     customer.CustomerService
	Rating       rating.RatingService
	Audit        audit.AuditService
	Catalog      catalog.CatalogService
}

// Connect supplies the modules built after admin; call it before serving.
func (m *Module) Connect(l Late) {
	m.Service.Connect(app.Peers{Bookings: peers.Bookings{Svc: l.Booking}, Verification: l.Verification, Console: app.Console{
		Providers: l.Provider, Customers: l.Customer, Verification: l.Verification, Bookings: l.Booking, Ratings: l.Rating,
		Identity: m.identity, Audit: l.Audit, Catalog: l.Catalog}})
}

// Subscribe keeps the dashboard read model current.
func (m *Module) Subscribe(bus *eventbus.Bus) {
	for name, h := range m.repo.StatsHandlers() {
		bus.Subscribe(name, "admin", h)
	}
}
