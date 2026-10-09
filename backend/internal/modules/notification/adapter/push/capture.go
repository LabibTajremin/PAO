// Package push delivers notifications to devices: FCM in production, an in-memory
// capture that logs for development and tests.
package push

import (
	"context"
	"errors"
	"log/slog"
	"strings"
	"sync"

	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/domain"
)

// Sent is one captured push.
type Sent struct {
	Token string
	Push  domain.Push
}

// Capture logs pushes and keeps the latest ones. Tokens starting with "invalid-" are
// rejected as dead and "broken-" ones fail, so token clean-up and failure logging can
// be exercised without FCM.
type Capture struct {
	log  *slog.Logger
	mu   sync.Mutex
	sent []Sent
}

// NewCapture returns the capture pusher.
func NewCapture(log *slog.Logger) *Capture { return &Capture{log: log} }

// Push implements port.Pusher.
func (c *Capture) Push(ctx context.Context, token string, p domain.Push) error {
	if strings.HasPrefix(token, "invalid-") {
		return domain.ErrInvalidToken
	}
	if strings.HasPrefix(token, "broken-") {
		return errors.New("push service unavailable")
	}
	c.log.InfoContext(ctx, "push", "title", p.Title, "type", p.Data["type"])
	c.mu.Lock()
	defer c.mu.Unlock()
	c.sent = append(c.sent, Sent{Token: token, Push: p})
	if len(c.sent) > 1000 {
		c.sent = c.sent[len(c.sent)-1000:]
	}
	return nil
}

// To returns the pushes captured for a token, oldest first.
func (c *Capture) To(token string) []Sent {
	c.mu.Lock()
	defer c.mu.Unlock()
	var out []Sent
	for _, s := range c.sent {
		if s.Token == token {
			out = append(out, s)
		}
	}
	return out
}
