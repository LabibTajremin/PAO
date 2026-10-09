//go:build integration

package migrations_test

import (
	"context"
	"database/sql"
	"os"
	"regexp"
	"testing"

	"gopkg.in/yaml.v3"

	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

// TestRBACSeed_CoversEveryPermissionInTheSpec guards the contract between the OpenAPI
// x-permission values and the seeded permissions.
func TestRBACSeed_CoversEveryPermissionInTheSpec(t *testing.T) {
	conn := openSeeded(t)
	for perm := range specPermissions(t) {
		if perm == "public" || perm == "authenticated" {
			continue
		}
		var roles int
		err := conn.QueryRow(`SELECT count(*) FROM identity.role_permissions WHERE permission = $1`, perm).Scan(&roles)
		if err != nil {
			t.Fatal(err)
		}
		if roles == 0 {
			t.Errorf("x-permission %q is granted to no role", perm)
		}
	}
}

// TestRBACSeed_AssignsEveryScreen checks every screen ID in 05-screens.md belongs to a role.
func TestRBACSeed_AssignsEveryScreen(t *testing.T) {
	conn := openSeeded(t)
	doc, err := os.ReadFile("../../docs/build/05-screens.md")
	if err != nil {
		t.Fatal(err)
	}
	ids := regexp.MustCompile(`(?m)^\| ([CMA][0-9]{2}b?(?:[,–] ?[CMA][0-9]{2}b?)*)`).FindAllStringSubmatch(string(doc), -1)
	seen := 0
	for _, row := range ids {
		for _, id := range expandIDs(row[1]) {
			seen++
			var roles int
			if err := conn.QueryRow(`SELECT count(*) FROM identity.role_screens WHERE screen_id = $1`, id).Scan(&roles); err != nil {
				t.Fatal(err)
			}
			if roles == 0 {
				t.Errorf("screen %s is assigned to no role", id)
			}
		}
	}
	if seen < 100 {
		t.Fatalf("parsed only %d screen IDs from 05-screens.md", seen)
	}
}

func openSeeded(t *testing.T) *sql.DB {
	t.Helper()
	conn, err := sql.Open("pgx", testkit.MigratedDatabase(t))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	if err := conn.PingContext(context.Background()); err != nil {
		t.Fatal(err)
	}
	return conn
}

func specPermissions(t *testing.T) map[string]bool {
	t.Helper()
	raw, err := os.ReadFile("../internal/platform/httpx/api/openapi.gen.yaml")
	if err != nil {
		t.Fatal(err)
	}
	var spec struct {
		Paths map[string]map[string]struct {
			Permission string `yaml:"x-permission"`
		} `yaml:"paths"`
	}
	if err := yaml.Unmarshal(raw, &spec); err != nil {
		t.Fatal(err)
	}
	perms := map[string]bool{}
	for path, ops := range spec.Paths {
		for method, op := range ops {
			if op.Permission == "" {
				t.Errorf("%s %s has no x-permission", method, path)
			}
			perms[op.Permission] = true
		}
	}
	return perms
}

// expandIDs turns "C02, C31" or "M05–M13" into individual screen IDs.
func expandIDs(cell string) []string {
	rangeRe := regexp.MustCompile(`^([CMA])([0-9]{2})–[CMA]([0-9]{2})$`)
	if m := rangeRe.FindStringSubmatch(cell); m != nil {
		var out []string
		var from, to int
		for _, c := range m[2] {
			from = from*10 + int(c-'0')
		}
		for _, c := range m[3] {
			to = to*10 + int(c-'0')
		}
		for n := from; n <= to; n++ {
			out = append(out, m[1]+string(rune('0'+n/10))+string(rune('0'+n%10)))
		}
		return out
	}
	return regexp.MustCompile(`[CMA][0-9]{2}b?`).FindAllString(cell, -1)
}
