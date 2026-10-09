// Package provider wires the provider module.
package provider

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	goredis "github.com/redis/go-redis/v9"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	catalog "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/peers"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/redis"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	rating "github.com/LabibTajremin/PAO/backend/internal/modules/rating/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// Deps are the shared services and peer contracts the module needs.
type Deps struct {
	Pool     *pgxpool.Pool
	Redis    goredis.Cmdable
	Keys     redisx.Keys
	Clock    clock.Clock
	IDs      idgen.Generator
	Log      *slog.Logger
	Catalog  catalog.CatalogService
	Identity identity.IdentityService
	Media    media.MediaService
	Admin    admin.AdminService
	Rating   rating.RatingService
}

// Module is the wired provider module.
type Module struct {
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
	handlers *postgres.Handlers
}

// New wires the module.
func New(d Deps) *Module {
	repo := postgres.New(d.Pool, outbox.NewWriter("provider", d.IDs, d.Clock), d.Clock)
	svc := app.New(app.Deps{Repo: repo, Presence: redis.New(d.Redis, d.Keys), Catalog: peers.Catalog{Svc: d.Catalog},
		Accounts: peers.Accounts{Svc: d.Identity}, Media: peers.Media{Svc: d.Media}, Ratings: peers.Ratings{Svc: d.Rating}, Clock: d.Clock, Log: d.Log})
	// Events also arrive for accounts that never enrolled as providers.
	offline := func(ctx context.Context, id uuid.UUID, reason string) error {
		if err := svc.GoOffline(ctx, id, reason); !errors.Is(err, domain.ErrNotFound) {
			return err
		}
		return nil
	}
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc),
		handlers: postgres.NewHandlers(repo, peers.Settings{Svc: d.Admin}, offline)}
}

// Subscribe registers the read-model and quality handlers (worker process).
func (m *Module) Subscribe(bus *eventbus.Bus) {
	for name, h := range m.handlers.Map() {
		bus.Subscribe(name, "provider", h)
	}
}

// RegisterJobs adds the presence reaper.
func (m *Module) RegisterJobs(r *jobs.Registry) {
	jobs.Register(r, inproc.NewReapWorker(m.Service))
	r.Every(time.Minute, inproc.ReapArgs{})
}
