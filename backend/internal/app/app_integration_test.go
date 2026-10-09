//go:build integration

package app_test

import (
	"context"
	"crypto/ed25519"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/getkin/kin-openapi/openapi3"

	"github.com/LabibTajremin/PAO/backend/internal/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/rbac"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

type noGrants struct{}

func (noGrants) LoadGrants(context.Context, string) (rbac.Grants, error) { return rbac.Grants{}, nil }

func testConfig(t *testing.T) config.Config {
	t.Helper()
	s3 := testkit.StorageConfig(t)
	_, key, _ := ed25519.GenerateKey(nil)
	return config.Config{
		AppEnv: config.EnvTest, DatabaseURL: testkit.MigratedDatabase(t), RedisURL: testkit.Env(t, "PAO_TEST_REDIS_URL"),
		S3: config.S3{Endpoint: s3.Endpoint, PublicEndpoint: s3.Endpoint, Region: s3.Region, AccessKey: s3.AccessKey,
			SecretKey: s3.SecretKey, BucketPrivate: "pao-test-private", BucketPublic: "pao-test-public"},
		JWT:             config.JWT{KeyID: "k1", SigningKey: key, PreviousKeys: map[string]ed25519.PublicKey{"k0": key.Public().(ed25519.PublicKey)}},
		AdminCORSOrigin: "http://admin",
	}
}

func TestAPIHandler_HealthAndReadiness(t *testing.T) {
	ctx := context.Background()
	infra, err := app.Connect(ctx, testConfig(t), logx.Discard())
	if err != nil {
		t.Fatal(err)
	}
	spec, _ := api.GetSpec()
	h, err := app.APIHandler(infra, spec, api.StrictUnimplemented{}, noGrants{})
	if err != nil {
		t.Fatal(err)
	}
	for path, want := range map[string]int{"/healthz": 200, "/readyz": 200, "/v1/customer/catalog": 401} {
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
		if rec.Code != want {
			t.Errorf("%s = %d, want %d", path, rec.Code, want)
		}
	}
	infra.Close()
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/readyz", nil))
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("readyz with dependencies down = %d", rec.Code)
	}
	broken := &openapi3.T{OpenAPI: "3.0.3", Paths: openapi3.NewPaths(openapi3.WithPath("/x/{id}", &openapi3.PathItem{
		Get: &openapi3.Operation{Responses: openapi3.NewResponses()},
	}))}
	if _, err := app.APIHandler(infra, broken, api.StrictUnimplemented{}, noGrants{}); err == nil {
		t.Fatal("broken spec accepted")
	}
}

func TestConnect_FailsOnEachDependency(t *testing.T) {
	ctx := context.Background()
	for name, mutate := range map[string]func(*config.Config){
		"database": func(c *config.Config) { c.DatabaseURL = "postgres://pao:pao@127.0.0.1:1/pao?connect_timeout=1" },
		"redis":    func(c *config.Config) { c.RedisURL = "redis://127.0.0.1:1/0" },
		"storage":  func(c *config.Config) { c.S3.SecretKey = "wrong" },
	} {
		t.Run(name, func(t *testing.T) {
			cfg := testConfig(t)
			mutate(&cfg)
			if _, err := app.Connect(ctx, cfg, logx.Discard()); err == nil {
				t.Fatal("connected")
			}
		})
	}
}
