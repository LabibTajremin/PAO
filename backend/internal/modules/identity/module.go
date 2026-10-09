// Package identity wires the identity module: accounts, sign-in, sessions and roles.
package identity

import (
	"log/slog"

	"github.com/jackc/pgx/v5/pgxpool"
	goredis "github.com/redis/go-redis/v9"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/redis"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
	"github.com/LabibTajremin/PAO/backend/internal/platform/rbac"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// Deps are the shared services the module needs.
type Deps struct {
	Pool   *pgxpool.Pool
	Redis  goredis.Cmdable
	Keys   redisx.Keys
	Clock  clock.Clock
	IDs    idgen.Generator
	Log    *slog.Logger
	Signer port.TokenSigner
	Cipher *auth.Cipher
	SMS    port.SMSSender
	Levels port.LevelReader
}

// Module is the wired identity module.
type Module struct {
	// Service exposes the use cases to the composition root (seed data, test kit).
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
	// Grants is the RBAC source other code uses to build the permission checker.
	Grants      rbac.Source
	Permissions *rbac.Checker
}

// New wires the module.
func New(d Deps) *Module {
	repo := postgres.New(d.Pool, outbox.NewWriter("identity", d.IDs, d.Clock), d.Clock)
	checker := rbac.NewChecker(d.Redis, d.Keys, repo)
	svc := app.New(app.Deps{
		Repo: repo, Codes: redis.NewCodes(d.Redis), Sessions: redis.NewSessions(d.Redis, d.Keys),
		Challenges: redis.NewChallenges(d.Redis, d.Keys), Limiter: redisx.NewRateLimiter(d.Redis, d.Clock, d.IDs),
		SMS: d.SMS, Signer: d.Signer, Denylist: redisx.NewDenylist(d.Redis, d.Keys), Permissions: checker,
		Levels: d.Levels, Secrets: d.Cipher, Keys: d.Keys, Clock: d.Clock, IDs: d.IDs, Log: d.Log,
	})
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc), Grants: repo, Permissions: checker}
}
