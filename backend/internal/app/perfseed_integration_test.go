//go:build integration

package app_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/app"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestSeedPerf_ProvidersAreFound(t *testing.T) {
	a := testkit.NewAPI(t)
	a.SeedCatalog(t)
	ctx := context.Background()
	var out bytes.Buffer
	if err := app.SeedPerf(ctx, a.Infra, a.Modules, 30, &out); err != nil {
		t.Fatal(err)
	}
	var f app.PerfFixture
	if err := json.Unmarshal(out.Bytes(), &f); err != nil || len(f.Tokens) != 50 {
		t.Fatalf("fixture: %v %d", err, len(f.Tokens))
	}
	path := fmt.Sprintf("/v1/customer/providers/nearby?serviceId=%s&subServiceId=%s&quantity=1&lat=%f&lng=%f&limit=100", f.ServiceID, f.SubServiceID, f.Lat, f.Lng)
	r := a.Do(t, "GET", path, nil, testkit.Bearer(f.Tokens[0]))
	if r.Status != 200 || len(r.JSON(t)["items"].([]any)) != 30 {
		t.Fatalf("nearby: %d %s", r.Status, r.Body)
	}
	a.Infra.Config.AppEnv = config.EnvProd
	if err := app.SeedPerf(ctx, a.Infra, a.Modules, 1, &out); err == nil {
		t.Fatal("perf seed ran in production")
	}
	a.Infra.Config.AppEnv = config.EnvTest
	a.Infra.Pool.Close()
	if err := app.SeedPerf(ctx, a.Infra, a.Modules, 1, &out); err == nil {
		t.Fatal("perf seed without a database")
	}
}
