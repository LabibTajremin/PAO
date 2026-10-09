// Package logx builds the structured JSON logger and carries request-scoped fields
// (request ID, user ID) through the context (PRD §11 observability).
package logx

import (
	"context"
	"io"
	"log/slog"
)

type ctxKey int

const (
	requestIDKey ctxKey = iota
	userIDKey
)

// New returns a JSON logger that adds request_id and user_id from the context to every
// record logged with a *Context method.
func New(w io.Writer, level slog.Level) *slog.Logger {
	return slog.New(contextHandler{slog.NewJSONHandler(w, &slog.HandlerOptions{Level: level})})
}

// WithRequestID stores the request ID for logging.
func WithRequestID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, requestIDKey, id)
}

// RequestID returns the request ID stored in ctx, or "".
func RequestID(ctx context.Context) string {
	id, _ := ctx.Value(requestIDKey).(string)
	return id
}

// WithUserID stores the authenticated account ID for logging.
func WithUserID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, userIDKey, id)
}

type contextHandler struct{ slog.Handler }

func (h contextHandler) Handle(ctx context.Context, r slog.Record) error {
	if id := RequestID(ctx); id != "" {
		r.AddAttrs(slog.String("request_id", id))
	}
	if id, _ := ctx.Value(userIDKey).(string); id != "" {
		r.AddAttrs(slog.String("user_id", id))
	}
	return h.Handler.Handle(ctx, r)
}

func (h contextHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	return contextHandler{h.Handler.WithAttrs(attrs)}
}

func (h contextHandler) WithGroup(name string) slog.Handler {
	return contextHandler{h.Handler.WithGroup(name)}
}

// Discard is a logger that drops everything; for tests.
func Discard() *slog.Logger { return slog.New(slog.DiscardHandler) }
