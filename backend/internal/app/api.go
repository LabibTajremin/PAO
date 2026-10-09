package app

import (
	"context"
	"crypto/ed25519"
	"fmt"
	"net/http"
	"time"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/go-chi/chi/v5"

	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/health"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// API rate limits per operation and subject.
var apiLimits = httpx.RateLimits{PerUser: 120, PerIP: 60, Window: time.Minute}

// APIHandler builds the public HTTP handler around the module servers. spec is the
// embedded contract (api.GetSpec).
func APIHandler(i *Infra, spec *openapi3.T, server api.StrictServerInterface, perms httpx.PermissionChecker) (http.Handler, error) {
	specRouter, err := httpx.NewSpecRouter(spec, i.Log)
	if err != nil {
		return nil, fmt.Errorf("build spec router: %w", err)
	}
	return httpx.NewRouter(httpx.RouterDeps{
		Log: i.Log, Spec: specRouter, Metrics: i.Metrics.Middleware,
		Verifier:    auth.NewVerifier(verificationKeys(i), i.Clock),
		Revoked:     redisx.NewDenylist(i.Redis, i.Keys),
		Permissions: perms,
		Limiter:     redisx.NewRateLimiter(i.Redis, i.Clock, i.IDs),
		Keys:        i.Keys, Limits: apiLimits,
		Idempotency: redisx.NewIdempotencyStore(i.Redis, 24*time.Hour),
		AdminOrigin: i.Config.AdminCORSOrigin, API: server,
		Mount: func(r chi.Router) { mountHealth(r, i) },
	}), nil
}

func verificationKeys(i *Infra) map[string]ed25519.PublicKey {
	keys := map[string]ed25519.PublicKey{}
	for kid, pub := range i.Config.JWT.PreviousKeys {
		keys[kid] = pub
	}
	keys[i.Config.JWT.KeyID] = i.Config.JWT.SigningKey.Public().(ed25519.PublicKey)
	return keys
}

func mountHealth(r chi.Router, i *Infra) {
	r.Get("/healthz", health.Liveness)
	r.Get("/readyz", health.Readiness(map[string]health.Checker{
		"database": health.CheckerFunc(i.Pool.Ping),
		"redis":    health.CheckerFunc(func(ctx context.Context) error { return i.Redis.Ping(ctx).Err() }),
		"storage": health.CheckerFunc(func(ctx context.Context) error {
			return i.Storage.Ping(ctx, i.Config.S3.BucketPrivate)
		}),
	}))
}
