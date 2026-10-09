//go:build integration

package http_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

const radius = "/v1/admin/settings/search.default_radius_m"

func TestSettings_UpdateIsAuditedAndSeenAtOnce(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	super := a.Admin(t, "super_admin")
	s, err := a.Modules.Admin.Contract.GetSettings(ctx)
	if err != nil || s.DefaultSearchRadiusM != 5000 || s.AcceptTimeoutASAP != 3*time.Minute || s.RatingFloor != 3.5 || s.DocumentRetention != 365*24*time.Hour {
		t.Fatalf("defaults: %+v %v", s, err)
	}
	r := a.Do(t, "PUT", radius, map[string]string{"value": "7000"}, testkit.Bearer(super.AccessToken))
	if r.Status != 200 || r.JSON(t)["value"] != "7000" || r.JSON(t)["updatedBy"] != super.ID.String() {
		t.Fatalf("update: %d %s", r.Status, r.Body)
	}
	if s, _ := a.Modules.Admin.Contract.GetSettings(ctx); s.DefaultSearchRadiusM != 7000 {
		t.Fatalf("stale settings: %+v", s)
	}
	a.RelayEvents(t)
	entries, err := a.Modules.Audit.Contract.ListForSubject(ctx, "setting", "search.default_radius_m", 10)
	if err != nil || len(entries) != 1 || entries[0].Before["value"] != "5000" || entries[0].After["value"] != "7000" {
		t.Fatalf("audit: %+v %v", entries, err)
	}
	r = a.Do(t, "GET", "/v1/admin/settings", nil, testkit.Bearer(super.AccessToken))
	if r.Status != 200 || len(r.JSON(t)["items"].([]any)) != 12 {
		t.Fatalf("list: %d %s", r.Status, r.Body)
	}
	if n, err := a.Modules.Admin.Contract.CountVerifiedComplaints(ctx, uuid.New()); err != nil || n != 0 {
		t.Fatalf("complaints: %d %v", n, err)
	}
}

func TestSettings_RejectsBadValuesAndRoles(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	super := testkit.Bearer(a.Admin(t, "super_admin").AccessToken)
	if r := a.Do(t, "PUT", radius, map[string]string{"value": "far"}, super); r.Code(t) != "SETTING_INVALID" {
		t.Fatalf("bad value: %s", r.Body)
	}
	if r := a.Do(t, "PUT", "/v1/admin/settings/no.such_key", map[string]string{"value": "1"}, super); r.Status != 404 {
		t.Fatalf("unknown key: %d", r.Status)
	}
	catalog := testkit.Bearer(a.Admin(t, "catalog_manager").AccessToken)
	if r := a.Do(t, "GET", "/v1/admin/settings", nil, catalog); r.Status != 200 {
		t.Fatalf("catalog manager read: %d", r.Status)
	}
	if r := a.Do(t, "PUT", radius, map[string]string{"value": "1"}, catalog); r.Status != 403 {
		t.Fatalf("catalog manager write: %d", r.Status)
	}
	if _, err := a.Infra.Pool.Exec(ctx, "UPDATE admin.settings SET value = 'x' WHERE type IN ('integer', 'number')"); err != nil {
		t.Fatal(err)
	}
	if s, err := a.Modules.Admin.Contract.GetSettings(ctx); err != nil || s.RatingFloor != 3.5 || s.StartCodeMaxAttempts != 5 {
		t.Fatalf("damaged rows fall back to defaults: %+v %v", s, err)
	}
	a.Do(t, "GET", "/v1/admin/settings", nil, super)
	a.Infra.Redis.Del(ctx, a.Infra.Keys.Key("cache", "settings"))
	a.Infra.Pool.Close()
	if r := a.Do(t, "GET", "/v1/admin/settings", nil, super); r.Status != 500 {
		t.Fatalf("closed pool list: %d", r.Status)
	}
	if r := a.Do(t, "PUT", radius, map[string]string{"value": "1"}, super); r.Status != 500 {
		t.Fatalf("closed pool update: %d", r.Status)
	}
	if _, err := a.Modules.Admin.Contract.GetSettings(ctx); err == nil {
		t.Fatal("settings without a database")
	}
}
