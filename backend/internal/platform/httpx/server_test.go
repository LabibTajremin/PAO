package httpx

import (
	"context"
	"net"
	"net/http"
	"testing"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/platform/logx"
)

func TestServe_ShutsDownGracefully(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan error, 1)
	go func() {
		done <- Runner{Server: NewServer("", ok200), Drain: time.Second, Log: logx.Discard()}.Run(ctx, ln)
	}()
	resp, err := http.Get("http://" + ln.Addr().String())
	if err != nil || resp.StatusCode != 200 {
		t.Fatalf("request: %v", err)
	}
	_ = resp.Body.Close()
	cancel()
	if err := <-done; err != nil {
		t.Fatalf("shutdown: %v", err)
	}
}

func TestServe_ReportsListenerFailure(t *testing.T) {
	ln, _ := net.Listen("tcp", "127.0.0.1:0")
	_ = ln.Close()
	if err := (Runner{Server: NewServer("", ok200), Drain: time.Second, Log: logx.Discard()}).Run(context.Background(), ln); err == nil {
		t.Fatal("closed listener served")
	}
}

type slowHandler struct{ started, release chan struct{} }

func (s slowHandler) ServeHTTP(http.ResponseWriter, *http.Request) {
	close(s.started)
	<-s.release
}

func TestServe_ReportsShutdownTimeout(t *testing.T) {
	ln, _ := net.Listen("tcp", "127.0.0.1:0")
	ctx, cancel := context.WithCancel(context.Background())
	h := slowHandler{started: make(chan struct{}), release: make(chan struct{})}
	defer close(h.release)
	done := make(chan error, 1)
	go func() {
		done <- Runner{Server: NewServer("", h), Drain: 50 * time.Millisecond, Log: logx.Discard()}.Run(ctx, ln)
	}()
	go func() {
		if resp, err := http.Get("http://" + ln.Addr().String()); err == nil {
			_ = resp.Body.Close()
		}
	}()
	<-h.started
	cancel()
	if err := <-done; err == nil {
		t.Fatal("drain timeout not reported")
	}
}
