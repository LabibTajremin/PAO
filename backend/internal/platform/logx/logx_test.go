package logx

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"testing"
)

func TestNew_AddsContextFields(t *testing.T) {
	var buf bytes.Buffer
	log := New(&buf, slog.LevelInfo).With("module", "booking").WithGroup("g")
	ctx := WithUserID(WithRequestID(context.Background(), "req-1"), "user-1")
	log.InfoContext(ctx, "accepted", "booking_id", "b1")

	var rec map[string]any
	if err := json.Unmarshal(buf.Bytes(), &rec); err != nil {
		t.Fatal(err)
	}
	g, _ := rec["g"].(map[string]any)
	if rec["module"] != "booking" || g["request_id"] != "req-1" || g["user_id"] != "user-1" || g["booking_id"] != "b1" {
		t.Fatalf("record = %v", rec)
	}
}

func TestNew_WithoutContextFields(t *testing.T) {
	var buf bytes.Buffer
	New(&buf, slog.LevelInfo).Info("plain")
	if bytes.Contains(buf.Bytes(), []byte("request_id")) {
		t.Fatalf("unexpected request_id: %s", buf.String())
	}
	if RequestID(context.Background()) != "" {
		t.Fatal("empty context has a request ID")
	}
	Discard().Info("dropped")
}
