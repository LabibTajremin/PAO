package api

import (
	"net/http"
	"testing"
)

// Seeded admins and the role each holds (docs/build/02-architecture.md §6).
const (
	super    = "super@pao.bd"
	verifier = "verifier@pao.bd"
	catalog  = "catalog@pao.bd"
	support  = "support@pao.bd"
)

// probe is one representative endpoint per admin permission. Probes that would change
// something name an ID or key that does not exist, so a permitted call stops at 404
// after the permission check and a forbidden one at 403 before it.
type probe struct {
	permission     string
	method, path   string
	body           any
	permittedCode  int
	permittedRoles []string
}

const missing = "00000000-0000-4000-8000-000000000000"

var probes = []probe{
	{"dashboard:read", "GET", "/v1/admin/dashboard", nil, 200, []string{super, verifier, catalog, support}},
	{"catalog:manage", "GET", "/v1/admin/catalog", nil, 200, []string{super, catalog}},
	{"settings:read", "GET", "/v1/admin/settings", nil, 200, []string{super, catalog}},
	{"settings:manage", "PUT", "/v1/admin/settings/no.such.setting", map[string]string{"value": "1"}, 404, []string{super}},
	{"verification:review", "GET", "/v1/admin/verifications", nil, 200, []string{super, verifier}},
	{"verification:docs:view", "GET", "/v1/admin/documents/" + missing + "/view-url", nil, 404, []string{super, verifier}},
	{"level2:manage", "GET", "/v1/admin/level2-sessions", nil, 200, []string{super, verifier}},
	{"provider:read", "GET", "/v1/admin/providers", nil, 200, []string{super, verifier, support}},
	{"provider:manage", "POST", "/v1/admin/providers/" + missing + "/status",
		map[string]string{"status": "suspended", "reason": "RBAC probe"}, 404, []string{super}},
	{"customer:read", "GET", "/v1/admin/customers", nil, 200, []string{super, support}},
	{"customer:manage", "POST", "/v1/admin/customers/" + missing + "/status",
		map[string]string{"status": "suspended", "reason": "RBAC probe"}, 404, []string{super}},
	{"booking:read:any", "GET", "/v1/admin/bookings", nil, 200, []string{super, support}},
	{"complaint:manage", "GET", "/v1/admin/complaints", nil, 200, []string{super, support}},
	{"audit:read", "GET", "/v1/admin/audit", nil, 200, []string{super}},
	{"admin_user:manage", "GET", "/v1/admin/admin-users", nil, 200, []string{super}},
	{"role:manage", "GET", "/v1/admin/roles", nil, 200, []string{super}},
}

func TestRBAC_EachAdminRoleReachesOnlyItsEndpoints(t *testing.T) {
	for _, email := range []string{super, verifier, catalog, support} {
		s := admin(t, email)
		for _, p := range probes {
			want := http.StatusForbidden
			for _, r := range p.permittedRoles {
				if r == email {
					want = p.permittedCode
				}
			}
			r := do(t, p.method, p.path, p.body, s)
			if r.Status != want {
				t.Errorf("%s %s %s (%s): want %d, got %d %s", email, p.method, p.path, p.permission, want, r.Status, r.Body)
			}
			if want == http.StatusForbidden && r.Code(t) != "FORBIDDEN" {
				t.Errorf("%s %s: error code %q", email, p.path, r.Code(t))
			}
		}
	}
}

func TestRBAC_AppUsersCannotReachTheAdminAPI(t *testing.T) {
	c := customer(t, phoneFor(t, "017", 51))
	for _, p := range probes {
		if r := do(t, p.method, p.path, p.body, c); r.Status != http.StatusForbidden {
			t.Errorf("customer %s %s: %d", p.method, p.path, r.Status)
		}
	}
	if r := do(t, "GET", "/v1/admin/dashboard", nil, session{}); r.Status != http.StatusUnauthorized {
		t.Errorf("anonymous dashboard: %d", r.Status)
	}
}
