// Package sms delivers texts: a console adapter for development and the SSL Wireless
// gateway for production (D10).
package sms

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"sync"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Console logs messages instead of sending them (dev). Codes appear in the API log.
type Console struct{ Log *slog.Logger }

// Send implements port.SMSSender.
func (c Console) Send(ctx context.Context, phone domain.Phone, message string) error {
	c.Log.InfoContext(ctx, "sms (console adapter)", "phone", string(phone), "message", message)
	return nil
}

// Capture keeps the latest message per phone in memory so end-to-end tests can read
// one-time codes; it is wired only when APP_ENV=test.
type Capture struct {
	mu   sync.Mutex
	last map[domain.Phone]string
}

// NewCapture returns an empty capture.
func NewCapture() *Capture { return &Capture{last: map[domain.Phone]string{}} }

// Send implements port.SMSSender.
func (c *Capture) Send(_ context.Context, phone domain.Phone, message string) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.last[phone] = message
	return nil
}

// Last returns the most recent message sent to phone.
func (c *Capture) Last(phone domain.Phone) string {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.last[phone]
}

// SSLWireless sends through the SSL Wireless SMS Plus API.
type SSLWireless struct {
	Endpoint string
	APIToken string
	SID      string
	Client   *http.Client
	IDs      idgen.Generator
}

type sslRequest struct {
	APIToken string `json:"api_token"`
	SID      string `json:"sid"`
	MSISDN   string `json:"msisdn"`
	SMS      string `json:"sms"`
	CSMSID   string `json:"csms_id"`
}

// Send implements port.SMSSender.
func (s SSLWireless) Send(ctx context.Context, phone domain.Phone, message string) error {
	body, _ := json.Marshal(sslRequest{ //nolint:gosec // the gateway API takes its token in the JSON body
		APIToken: s.APIToken, SID: s.SID, MSISDN: strings.TrimPrefix(string(phone), "+"), SMS: message,
		CSMSID: strings.ReplaceAll(s.IDs.New().String(), "-", "")[:20],
	})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.Endpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("build sms request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := s.Client.Do(req)
	if err != nil {
		return fmt.Errorf("sms gateway: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()
	var out struct {
		StatusCode int `json:"status_code"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil || out.StatusCode != http.StatusOK {
		return fmt.Errorf("sms gateway rejected the message (http %d, status %d)", resp.StatusCode, out.StatusCode)
	}
	return nil
}
