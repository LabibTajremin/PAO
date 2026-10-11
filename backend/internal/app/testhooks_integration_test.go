//go:build integration

package app_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/app"
	catalogapp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func hookGet(t *testing.T, url string) (int, map[string]any) {
	t.Helper()
	resp, err := http.Get(url) //nolint:noctx // test against a local server
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = resp.Body.Close() }()
	var body map[string]any
	_ = json.NewDecoder(resp.Body).Decode(&body)
	return resp.StatusCode, body
}

func hookPost(t *testing.T, url string) int {
	t.Helper()
	resp, err := http.Post(url, "", nil) //nolint:noctx // test against a local server
	if err != nil {
		t.Fatal(err)
	}
	_ = resp.Body.Close()
	return resp.StatusCode
}

func TestTestHooks_ReadCapturesAndExpireDocuments(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	next := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusTeapot) })
	srv := httptest.NewServer(app.WithTestHooks(next, a.Infra, a.Modules))
	t.Cleanup(srv.Close)
	if code, _ := hookGet(t, srv.URL+"/v1/anything"); code != http.StatusTeapot {
		t.Fatalf("other paths reach the API: %d", code)
	}
	_ = a.Modules.SMSCapture.Send(ctx, "+8801712345601", "Your PAO code is 123456")
	if code, body := hookGet(t, srv.URL+"/__test/sms?phone=01712345601"); code != 200 || body["message"] != "Your PAO code is 123456" {
		t.Fatalf("sms: %d %v", code, body)
	}
	for q, want := range map[string]int{"phone=123": 400, "phone=01712345609": 404} {
		if code, _ := hookGet(t, srv.URL+"/__test/sms?"+q); code != want {
			t.Errorf("sms %s: %d", q, code)
		}
	}
	_ = a.Modules.PushCapture.Push(ctx, "e2e-token", domain.Push{Title: "New request", Data: map[string]string{"type": "booking.requested"}})
	if _, body := hookGet(t, srv.URL+"/__test/pushes?token=e2e-token"); len(body["pushes"].([]any)) != 1 {
		t.Fatalf("pushes: %v", body)
	}
	a.SeedCatalog(t)
	p := a.VerifiedProvider(t, "01712345602", "male", catalogapp.SeedID("service", "electrician"))
	if code := hookPost(t, srv.URL+"/__test/verification/expire?at=yesterday"); code != 400 {
		t.Fatalf("bad time: %d", code)
	}
	at := time.Now().AddDate(10, 0, 0).UTC().Format(time.RFC3339)
	if code := hookPost(t, srv.URL+"/__test/verification/expire?at="+at); code != 204 {
		t.Fatalf("expire: %d", code)
	}
	if lvl, err := a.Modules.Verification.Contract.GetLevel(ctx, p.ID); err != nil || lvl != 0 {
		t.Fatalf("expired documents keep level %d (%v)", lvl, err)
	}
	a.Infra.Pool.Close()
	if code := hookPost(t, srv.URL+"/__test/verification/expire?at="+at); code != 500 {
		t.Fatalf("expire with a closed pool: %d", code)
	}
}

func TestTestHooks_OnlyInTestAndWithoutCaptures(t *testing.T) {
	a := testkit.NewAPI(t)
	next := http.NotFoundHandler()
	dev := *a.Infra
	dev.Config.AppEnv = config.EnvDev
	if got := app.WithTestHooks(next, &dev, a.Modules); got == nil {
		t.Fatal("nil handler")
	} else if code, _ := hookGetHandler(t, got, "/__test/sms?phone=01712345601"); code != 404 {
		t.Fatalf("hooks outside test: %d", code)
	}
	bare := *a.Modules
	bare.SMSCapture, bare.PushCapture = nil, nil
	h := app.WithTestHooks(next, a.Infra, &bare)
	if code, _ := hookGetHandler(t, h, "/__test/sms?phone=01712345601"); code != 404 {
		t.Fatalf("no sms capture: %d", code)
	}
	if code, body := hookGetHandler(t, h, "/__test/pushes?token=x"); code != 200 || len(body["pushes"].([]any)) != 0 {
		t.Fatalf("no push capture: %d %v", code, body)
	}
}

func hookGetHandler(t *testing.T, h http.Handler, path string) (int, map[string]any) {
	t.Helper()
	srv := httptest.NewServer(h)
	defer srv.Close()
	return hookGet(t, srv.URL+path)
}
