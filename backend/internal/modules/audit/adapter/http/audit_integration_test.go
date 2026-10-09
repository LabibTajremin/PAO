//go:build integration

package http_test

import (
	"context"
	"net/url"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestAudit_EventsBecomeEntriesOnce(t *testing.T) {
	a := testkit.NewAPI(t)
	super := a.Admin(t, "super_admin")
	customer := a.SignIn(t, "01712345678", "customer")
	_, err := a.Modules.Identity.Contract.SetAccountStatus(context.Background(), identity.SetAccountStatusInput{
		AccountID: customer.Account.Id, Status: identity.StatusSuspended, Reason: "abuse", ActorID: super.ID,
	})
	if err != nil {
		t.Fatal(err)
	}
	a.RelayEvents(t)
	if _, err := a.Infra.Pool.Exec(context.Background(), "UPDATE identity.outbox SET published_at = NULL"); err != nil {
		t.Fatal(err)
	}
	a.RelayEvents(t)
	r := a.Do(t, "GET", "/v1/admin/audit?action=account.status_changed&subjectId="+customer.Account.Id.String(), nil, testkit.Bearer(super.AccessToken))
	items := r.JSON(t)["items"].([]any)
	if r.Status != 200 || len(items) != 1 || items[0].(map[string]any)["reason"] != "abuse" {
		t.Fatalf("audit: %d %s", r.Status, r.Body)
	}
	history, err := a.Modules.Audit.Contract.ListForSubject(context.Background(), "account", customer.Account.Id.String(), 10)
	if err != nil || len(history) != 1 || *history[0].ActorID != super.ID {
		t.Fatalf("history: %+v %v", history, err)
	}
}

func TestAudit_PagingFiltersAndAppendOnly(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	super := testkit.Bearer(a.Admin(t, "super_admin").AccessToken)
	actor := uuid.New()
	base := time.Date(2026, 10, 1, 0, 0, 0, 0, time.UTC)
	for i := 0; i < 3; i++ {
		err := a.Modules.Audit.Contract.Record(ctx, contract.Entry{At: base.Add(time.Duration(i) * time.Hour), ActorID: &actor, ActorRole: "verifier",
			Action: "verification.item_approved", SubjectType: "provider", SubjectID: "p1", Before: map[string]any{"a": 1}, After: map[string]any{"b": 2}})
		if err != nil {
			t.Fatal(err)
		}
	}
	q := url.Values{"actorId": {actor.String()}, "limit": {"2"}, "from": {base.Format(time.RFC3339)}, "to": {base.Add(5 * time.Hour).Format(time.RFC3339)}}
	r := a.Do(t, "GET", "/v1/admin/audit?"+q.Encode(), nil, super)
	page := r.JSON(t)
	if r.Status != 200 || len(page["items"].([]any)) != 2 || page["nextCursor"] == nil {
		t.Fatalf("first page: %d %s", r.Status, r.Body)
	}
	q.Set("cursor", page["nextCursor"].(string))
	r = a.Do(t, "GET", "/v1/admin/audit?"+q.Encode(), nil, super)
	if len(r.JSON(t)["items"].([]any)) != 1 || r.JSON(t)["nextCursor"] != nil {
		t.Fatalf("second page: %s", r.Body)
	}
	if r := a.Do(t, "GET", "/v1/admin/audit?cursor=%25%25", nil, super); r.Status != 422 {
		t.Fatalf("bad cursor: %d", r.Status)
	}
	for _, stmt := range []string{"UPDATE audit.entries SET reason = 'x'", "DELETE FROM audit.entries", "TRUNCATE audit.entries"} {
		if _, err := a.Infra.Pool.Exec(ctx, stmt); err == nil {
			t.Errorf("%s allowed", stmt)
		}
	}
	a.Do(t, "GET", "/v1/admin/audit", nil, super)
	a.Infra.Pool.Close()
	if r := a.Do(t, "GET", "/v1/admin/audit", nil, super); r.Status != 500 {
		t.Fatalf("closed pool: %d", r.Status)
	}
}

func TestAudit_SparseEntries(t *testing.T) {
	a := testkit.NewAPI(t)
	super := testkit.Bearer(a.Admin(t, "super_admin").AccessToken)
	if err := a.Modules.Audit.Contract.Record(context.Background(), contract.Entry{Action: "system.note", SubjectType: "system", SubjectID: "s"}); err != nil {
		t.Fatal(err)
	}
	r := a.Do(t, "GET", "/v1/admin/audit?subjectId=s", nil, super)
	item := r.JSON(t)["items"].([]any)[0].(map[string]any)
	if item["before"] != nil || item["actorRole"] != nil {
		t.Fatalf("sparse entry: %v", item)
	}
}
