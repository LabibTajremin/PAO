// Package admin wires the admin module.
package admin

import (
	"log/slog"

	"github.com/jackc/pgx/v5/pgxpool"
	goredis "github.com/redis/go-redis/v9"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// Deps are the shared services the module needs.
type Deps struct {
	Pool  *pgxpool.Pool
	Redis goredis.Cmdable
	Keys  redisx.Keys
	Clock clock.Clock
	IDs   idgen.Generator
	Log   *slog.Logger
}

// Module is the wired admin module.
type Module struct {
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
}

// New wires the module.
func New(d Deps) *Module {
	repo := postgres.New(d.Pool, outbox.NewWriter("admin", d.IDs, d.Clock))
	svc := app.New(app.Deps{Repo: repo, Cache: redisx.NewCache(d.Redis), Keys: d.Keys, Clock: d.Clock, Log: d.Log})
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc)}
}
