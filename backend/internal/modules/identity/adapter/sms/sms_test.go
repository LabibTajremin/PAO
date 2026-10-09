package sms

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

func TestConsoleAndCapture(t *testing.T) {
	if err := (Console{Log: logx.Discard()}).Send(context.Background(), "+8801712345678", "hi"); err != nil {
		t.Fatal(err)
	}
	c := NewCapture()
	_ = c.Send(context.Background(), "+8801712345678", "code 123456")
	if c.Last("+8801712345678") != "code 123456" {
		t.Fatal("capture lost the message")
	}
}

func TestSSLWireless(t *testing.T) {
	var got sslRequest
	status := 200
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewDecoder(r.Body).Decode(&got)
		_ = json.NewEncoder(w).Encode(map[string]int{"status_code": status})
	}))
	defer srv.Close()
	s := SSLWireless{Endpoint: srv.URL, APIToken: "tok", SID: "PAO", Client: srv.Client(), IDs: idgen.V7{}}
	if err := s.Send(context.Background(), "+8801712345678", "hi"); err != nil {
		t.Fatal(err)
	}
	if got.MSISDN != "8801712345678" || got.APIToken != "tok" || len(got.CSMSID) != 20 {
		t.Fatalf("request = %+v", got)
	}
	status = 4001
	if err := s.Send(context.Background(), "+8801712345678", "hi"); err == nil {
		t.Fatal("rejection not reported")
	}
	s.Endpoint = "http://127.0.0.1:1"
	if err := s.Send(context.Background(), "+8801712345678", "hi"); err == nil {
		t.Fatal("unreachable gateway not reported")
	}
	s.Endpoint = "://bad"
	if err := s.Send(context.Background(), "+8801712345678", "hi"); err == nil {
		t.Fatal("bad endpoint not reported")
	}
}
