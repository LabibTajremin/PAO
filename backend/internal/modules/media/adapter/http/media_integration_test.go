//go:build integration

package http_test

import (
	"bytes"
	"context"
	"net/http"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/media/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

var jpeg = bytes.Repeat([]byte{0xff}, 1024)

func put(t *testing.T, ticket api.UploadTicket, body []byte) {
	t.Helper()
	if status := send(t, ticket, body); status != http.StatusOK {
		t.Fatalf("put: %d", status)
	}
}

func send(t *testing.T, ticket api.UploadTicket, body []byte) int {
	t.Helper()
	req, _ := http.NewRequest(http.MethodPut, ticket.UploadUrl, bytes.NewReader(body))
	for k, v := range ticket.Headers {
		req.Header.Set(k, v)
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	_ = res.Body.Close()
	return res.StatusCode
}

func upload(t *testing.T, a *testkit.API, token, app, purpose string, body []byte) api.UploadTicket {
	t.Helper()
	r := a.Do(t, "POST", "/v1/"+app+"/uploads", map[string]any{"purpose": purpose, "contentType": "image/jpeg", "sizeBytes": len(body)}, testkit.Bearer(token))
	if r.Status != http.StatusCreated {
		t.Fatalf("create upload: %d %s", r.Status, r.Body)
	}
	var ticket api.UploadTicket
	r.Decode(t, &ticket)
	return ticket
}

func TestMedia_ProviderDocumentIsUploadedConfirmedAndViewedWithAudit(t *testing.T) {
	a := testkit.NewAPI(t)
	provider := a.SignIn(t, "01712345601", "partner").AccessToken
	ticket := upload(t, a, provider, "provider", "nid_front", jpeg)
	confirm := "/v1/provider/uploads/" + ticket.MediaId.String() + "/confirm"
	if r := a.Do(t, "POST", confirm, nil, testkit.Bearer(provider)); r.Code(t) != "UPLOAD_NOT_FOUND" {
		t.Fatalf("confirm before put: %s", r.Body)
	}
	put(t, ticket, jpeg)
	for range 2 {
		if r := a.Do(t, "POST", confirm, nil, testkit.Bearer(provider)); r.Status != 200 || r.JSON(t)["status"] != "confirmed" {
			t.Fatalf("confirm: %d %s", r.Status, r.Body)
		}
	}
	other := a.SignIn(t, "01712345602", "partner").AccessToken
	if r := a.Do(t, "POST", confirm, nil, testkit.Bearer(other)); r.Status != 404 {
		t.Fatalf("other owner: %d", r.Status)
	}
	verifier := a.Admin(t, "verifier")
	r := a.Do(t, "GET", "/v1/admin/documents/"+ticket.MediaId.String()+"/view-url", nil, testkit.Bearer(verifier.AccessToken))
	if r.Status != 200 {
		t.Fatalf("view: %d %s", r.Status, r.Body)
	}
	res, err := http.Get(r.JSON(t)["url"].(string))
	if err != nil || res.StatusCode != 200 {
		t.Fatalf("download: %v %v", res, err)
	}
	_ = res.Body.Close()
	entries, err := a.Modules.Audit.Contract.ListForSubject(context.Background(), "media", ticket.MediaId.String(), 10)
	if err != nil || len(entries) != 1 || entries[0].Action != "media.document_viewed" || *entries[0].ActorID != verifier.ID {
		t.Fatalf("audit: %+v %v", entries, err)
	}
	if r := a.Do(t, "GET", "/v1/admin/documents/"+uuid.NewString()+"/view-url", nil, testkit.Bearer(verifier.AccessToken)); r.Status != 404 {
		t.Fatalf("unknown document: %d", r.Status)
	}
}

func TestMedia_CustomerUploadRules(t *testing.T) {
	a := testkit.NewAPI(t)
	customer := a.SignIn(t, "01712345603", "customer").AccessToken
	ticket := upload(t, a, customer, "customer", "avatar", jpeg)
	if status := send(t, ticket, jpeg[:10]); status != http.StatusForbidden {
		t.Fatalf("signed size not enforced: %d", status)
	}
	cases := []map[string]any{
		{"purpose": "nid_front", "contentType": "image/jpeg", "sizeBytes": 10},
		{"purpose": "avatar", "contentType": "application/pdf", "sizeBytes": 10},
		{"purpose": "avatar", "contentType": "image/png", "sizeBytes": 3 << 20},
	}
	for _, body := range cases {
		if r := a.Do(t, "POST", "/v1/customer/uploads", body, testkit.Bearer(customer)); r.Code(t) != "UPLOAD_INVALID" {
			t.Errorf("%v: %d %s", body, r.Status, r.Body)
		}
	}
	if r := a.Do(t, "POST", "/v1/customer/uploads/"+uuid.NewString()+"/confirm", nil, testkit.Bearer(customer)); r.Status != 404 {
		t.Fatalf("unknown upload: %d", r.Status)
	}
	level2 := map[string]any{"purpose": "level2_photo", "contentType": "image/jpeg", "sizeBytes": 10}
	if r := a.Do(t, "POST", "/v1/provider/uploads", level2, testkit.Bearer(a.Token(t, uuid.New(), "provider"))); r.Code(t) != "UPLOAD_INVALID" {
		t.Fatalf("provider level2 upload: %s", r.Body)
	}
	ok := upload(t, a, customer, "customer", "complaint_photo", jpeg)
	put(t, ok, jpeg)
	if r := a.Do(t, "POST", "/v1/customer/uploads/"+ok.MediaId.String()+"/confirm", nil, testkit.Bearer(customer)); r.Status != 200 {
		t.Fatalf("confirm: %d %s", r.Status, r.Body)
	}
	a.Infra.Pool.Close()
	if r := a.Do(t, "POST", "/v1/customer/uploads", cases[0], testkit.Bearer(customer)); r.Status != 422 {
		t.Fatalf("closed pool, invalid: %d", r.Status)
	}
	body := map[string]any{"purpose": "avatar", "contentType": "image/jpeg", "sizeBytes": 10}
	if r := a.Do(t, "POST", "/v1/provider/uploads", body, testkit.Bearer(a.Token(t, uuid.New(), "provider"))); r.Status != 500 {
		t.Fatalf("closed pool: %d", r.Status)
	}
	if r := a.Do(t, "POST", "/v1/provider/uploads/"+uuid.NewString()+"/confirm", nil, testkit.Bearer(a.Token(t, uuid.New(), "provider"))); r.Status != 500 {
		t.Fatalf("closed pool confirm: %d", r.Status)
	}
}

func TestMedia_ContractAndOrphanPurge(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	c := a.Modules.Media.Contract
	owner := uuid.New()
	req := contract.UploadRequest{OwnerID: owner, Purpose: contract.PurposeLevel2Photo, ContentType: "image/jpeg", SizeBytes: int64(len(jpeg))}
	kept, err := c.CreateUploadURL(ctx, req)
	if err != nil {
		t.Fatal(err)
	}
	put(t, api.UploadTicket{UploadUrl: kept.URL, Headers: kept.Headers}, jpeg)
	if o, err := c.ConfirmUpload(ctx, owner, kept.MediaID); err != nil || !o.Confirmed {
		t.Fatalf("confirm: %+v %v", o, err)
	}
	if err := c.MarkAttached(ctx, kept.MediaID); err != nil {
		t.Fatal(err)
	}
	orphan, _ := c.CreateUploadURL(ctx, req)
	if _, err := c.CreateUploadURL(ctx, contract.UploadRequest{OwnerID: owner, Purpose: contract.PurposeAvatar}); err == nil {
		t.Fatal("admin avatar upload allowed")
	}
	if _, err := c.ConfirmUpload(ctx, owner, orphan.MediaID); err == nil {
		t.Fatal("confirmed a missing file")
	}
	if _, err := c.GetViewURL(ctx, contract.ViewRequest{MediaID: orphan.MediaID}); err == nil {
		t.Fatal("viewed an unconfirmed file")
	}
	a.Modules.RegisterJobs(jobs.NewRegistry())
	a.Clock.Advance(25 * time.Hour)
	if err := inproc.NewPurgeWorker(a.Modules.Media.Service).Work(ctx, nil); err != nil {
		t.Fatal(err)
	}
	if _, err := c.GetObject(ctx, orphan.MediaID); err == nil {
		t.Fatal("orphan survived")
	}
	if o, err := c.GetObject(ctx, kept.MediaID); err != nil || o.Purpose != contract.PurposeLevel2Photo {
		t.Fatalf("attached object: %+v %v", o, err)
	}
	if err := c.Delete(ctx, kept.MediaID); err != nil {
		t.Fatal(err)
	}
	if err := c.MarkAttached(ctx, kept.MediaID); err == nil {
		t.Fatal("attached a deleted object")
	}
	if err := c.Delete(ctx, kept.MediaID); err == nil {
		t.Fatal("deleted twice")
	}
	a.Infra.Pool.Close()
	if err := inproc.NewPurgeWorker(a.Modules.Media.Service).Work(ctx, nil); err == nil {
		t.Fatal("purge with closed pool")
	}
}
