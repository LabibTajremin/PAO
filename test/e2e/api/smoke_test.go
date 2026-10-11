package api

import (
	"net/http"
	"testing"
)

// TestSmoke_ServicesStartAndAreReady proves the composition roots work: cmd/api and
// cmd/worker started and are ready, and cmd/migrate migrated and seeded the database.
// Those main packages are excluded from unit coverage, so the stack is their test.
func TestSmoke_ServicesStartAndAreReady(t *testing.T) {
	for _, probe := range []struct{ base, path string }{
		{stack.api, "/healthz"}, {stack.api, "/readyz"}, {stack.worker, "/healthz"},
	} {
		if r := call(t, probe.base, "GET", probe.path, nil, session{}); r.Status != http.StatusOK {
			t.Errorf("%s%s: %d %s", probe.base, probe.path, r.Status, r.Body)
		}
	}
	c := customer(t, phoneFor(t, "017", 71))
	tree := must(t, 200, "GET", "/v1/customer/catalog", nil, c)
	if cats, _ := tree["categories"].([]any); len(cats) == 0 {
		t.Fatalf("seeded catalog not served: %v", tree)
	}
	if o := catalogService(t, c, "Electrician"); len(o.Subs) == 0 || o.Subs[0].Price <= 0 {
		t.Fatalf("seeded prices missing: %+v", o)
	}
}
