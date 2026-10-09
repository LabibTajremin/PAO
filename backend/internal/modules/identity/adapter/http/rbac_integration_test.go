//go:build integration

package http_test

import (
	"context"
	"net/http"
	"os"
	"regexp"
	"strings"
	"testing"

	"github.com/google/uuid"
	"gopkg.in/yaml.v3"

	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

type operation struct{ method, path, permission string }

func protectedOperations(t *testing.T) []operation {
	t.Helper()
	raw, err := os.ReadFile("../../../../platform/httpx/api/openapi.gen.yaml")
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
	fill := strings.NewReplacer("{role}", "customer", "{itemType}", "nid", "{key}", "booking.accept_timeout_asap_seconds")
	param := regexp.MustCompile(`\{[a-zA-Z]+\}`)
	var out []operation
	for path, ops := range spec.Paths {
		for method, op := range ops {
			if op.Permission != "public" && op.Permission != "authenticated" {
				out = append(out, operation{strings.ToUpper(method), param.ReplaceAllString(fill.Replace(path), uuid.NewString()), op.Permission})
			}
		}
	}
	return out
}

// TestEveryRole_ReachesExactlyItsPermissions walks the spec once per role: a route is
// forbidden exactly when the role's seeded permissions lack its x-permission.
func TestEveryRole_ReachesExactlyItsPermissions(t *testing.T) {
	a := testkit.NewAPI(t)
	rows, err := a.Infra.Pool.Query(context.Background(), "SELECT role, permission FROM identity.role_permissions")
	if err != nil {
		t.Fatal(err)
	}
	grants := map[string]map[string]bool{}
	for rows.Next() {
		var role, perm string
		if err := rows.Scan(&role, &perm); err != nil {
			t.Fatal(err)
		}
		if grants[role] == nil {
			grants[role] = map[string]bool{}
		}
		grants[role][perm] = true
	}
	ops := protectedOperations(t)
	for role, has := range grants {
		token := testkit.Bearer(a.Token(t, uuid.New(), role))
		for _, op := range ops {
			r := a.Do(t, op.method, op.path, nil, token)
			if forbidden := r.Status == http.StatusForbidden; forbidden == has[op.permission] {
				t.Errorf("%s: %s %s (%s) = %d %s", role, op.method, op.path, op.permission, r.Status, r.Body)
			}
		}
	}
	if len(grants) != 6 {
		t.Fatalf("roles: %v", grants)
	}
}
