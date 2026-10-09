package push

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

// ServiceAccount returns a throwaway service-account key; parsing it needs no network.
func ServiceAccount(t *testing.T) []byte {
	t.Helper()
	key, _ := rsa.GenerateKey(rand.Reader, 2048)
	der, _ := x509.MarshalPKCS8PrivateKey(key)
	raw, _ := json.Marshal(map[string]string{"type": "service_account", "project_id": "pao-test", "client_email": "push@pao-test.iam.gserviceaccount.com",
		"private_key": string(pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: der})), "token_uri": "https://oauth2.googleapis.com/token"})
	return raw
}

func TestFCM(t *testing.T) {
	f, err := NewFCM(context.Background(), ServiceAccount(t))
	if err != nil || f.endpoint != "https://fcm.googleapis.com/v1/projects/pao-test/messages:send" {
		t.Fatalf("new: %v %v", f, err)
	}
	var got fcmMessage
	status := http.StatusOK
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewDecoder(r.Body).Decode(&got)
		w.WriteHeader(status)
	}))
	f.client, f.endpoint = srv.Client(), srv.URL
	ctx := context.Background()
	p := domain.Push{Title: "Booking accepted", Body: "Rahim accepted", Data: map[string]string{"type": "booking_accepted"}}
	if err := f.Push(ctx, "tok", p); err != nil || got.Message.Token != "tok" || got.Message.Notification["title"] != "Booking accepted" {
		t.Fatalf("push: %+v %v", got, err)
	}
	for _, s := range []int{http.StatusNotFound, http.StatusBadRequest} {
		status = s
		if err := f.Push(ctx, "tok", p); !errors.Is(err, domain.ErrInvalidToken) {
			t.Errorf("%d: %v", s, err)
		}
	}
	status = http.StatusInternalServerError
	if err := f.Push(ctx, "tok", p); err == nil || errors.Is(err, domain.ErrInvalidToken) {
		t.Fatalf("500: %v", err)
	}
	srv.Close()
	if err := f.Push(ctx, "tok", p); err == nil {
		t.Fatal("closed server")
	}
	if _, err := NewFCM(ctx, []byte("{")); err == nil {
		t.Fatal("bad credentials")
	}
}

func TestCapture(t *testing.T) {
	c := NewCapture(logx.Discard())
	ctx := context.Background()
	if err := c.Push(ctx, "invalid-1", domain.Push{}); !errors.Is(err, domain.ErrInvalidToken) {
		t.Fatal(err)
	}
	if err := c.Push(ctx, "broken-1", domain.Push{}); err == nil || errors.Is(err, domain.ErrInvalidToken) {
		t.Fatal(err)
	}
	for i := range 1001 {
		_ = c.Push(ctx, "tok-"+strconv.Itoa(i%2), domain.Push{Title: strconv.Itoa(i), Data: map[string]string{}})
	}
	if got := c.To("tok-0"); len(got) != 500 || got[len(got)-1].Push.Title != "1000" {
		t.Fatalf("captured %d", len(got))
	}
}
