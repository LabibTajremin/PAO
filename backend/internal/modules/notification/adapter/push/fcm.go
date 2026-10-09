package push

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"golang.org/x/oauth2/google"

	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/domain"
)

const fcmScope = "https://www.googleapis.com/auth/firebase.messaging"

// FCM sends through the Firebase Cloud Messaging HTTP v1 API.
type FCM struct {
	client   *http.Client
	endpoint string
}

// NewFCM authenticates with a service-account key (FCM_CREDENTIALS_FILE contents).
func NewFCM(ctx context.Context, credentials []byte) (*FCM, error) {
	creds, err := google.CredentialsFromJSON(ctx, credentials, fcmScope) //nolint:staticcheck // the file is our own service account key
	if err != nil {
		return nil, fmt.Errorf("fcm credentials: %w", err)
	}
	endpoint := "https://fcm.googleapis.com/v1/projects/" + creds.ProjectID + "/messages:send"
	return &FCM{client: oauthClient(ctx, creds), endpoint: endpoint}, nil
}

type fcmMessage struct {
	Message struct {
		Token        string            `json:"token"`
		Notification map[string]string `json:"notification"`
		Data         map[string]string `json:"data,omitempty"`
		Android      map[string]string `json:"android"`
	} `json:"message"`
}

// Push implements port.Pusher. FCM answers 404 (UNREGISTERED) or 400 for tokens that
// will never work again; those become domain.ErrInvalidToken.
func (f *FCM) Push(ctx context.Context, token string, p domain.Push) error {
	var m fcmMessage
	m.Message.Token, m.Message.Data = token, p.Data
	m.Message.Notification = map[string]string{"title": p.Title, "body": p.Body}
	m.Message.Android = map[string]string{"priority": "high"}
	raw, _ := json.Marshal(m)
	req, _ := http.NewRequestWithContext(ctx, http.MethodPost, f.endpoint, bytes.NewReader(raw))
	req.Header.Set("Content-Type", "application/json")
	res, err := f.client.Do(req)
	if err != nil {
		return fmt.Errorf("fcm: %w", err)
	}
	defer func() { _ = res.Body.Close() }()
	switch {
	case res.StatusCode == http.StatusNotFound || res.StatusCode == http.StatusBadRequest:
		return domain.ErrInvalidToken
	case res.StatusCode >= 300:
		body, _ := io.ReadAll(io.LimitReader(res.Body, 512))
		return fmt.Errorf("fcm: %d %s", res.StatusCode, body)
	}
	return nil
}
