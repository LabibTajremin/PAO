// Package booking wires the booking module.
package booking

import (
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/adapter/peers"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/app"
	catalog "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	customer "github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Deps are the shared services and peer contracts the module needs.
type Deps struct {
	Pool         *pgxpool.Pool
	Clock        clock.Clock
	IDs          idgen.Generator
	Catalog      catalog.CatalogService
	Customer     customer.CustomerService
	Identity     identity.IdentityService
	Provider     provider.ProviderService
	Verification verification.VerificationService
	Media        media.MediaService
	Admin        admin.AdminService
}

// Module is the wired booking module.
type Module struct {
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
}

// New wires the module.
func New(d Deps) *Module {
	providers := peers.Providers{Svc: d.Provider, Verification: d.Verification}
	svc := app.New(app.Deps{Repo: postgres.New(d.Pool, outbox.NewWriter("booking", d.IDs, d.Clock), d.Clock),
		Catalog: peers.Catalog{Svc: d.Catalog}, Customers: peers.Customers{Svc: d.Customer, Identity: d.Identity},
		Providers: providers, Finder: providers, Media: peers.Media{Svc: d.Media}, Settings: peers.Settings{Svc: d.Admin},
		Clock: d.Clock, IDs: d.IDs, Code: func() string { return auth.RandomDigits(4) }, Dhaka: clock.Dhaka})
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc)}
}

// RegisterJobs adds the request expiry sweep.
func (m *Module) RegisterJobs(r *jobs.Registry) {
	jobs.Register(r, inproc.NewExpireWorker(m.Service))
	r.Every(15*time.Second, inproc.ExpireArgs{})
}
