package app

import (
	"context"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity"
	identityhttp "github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/sms"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Server serves every API operation. Each module's handler is embedded at depth one;
// operations no module implements yet fall through to the depth-two fallback.
type Server struct {
	*identityhttp.Handler
	unimplemented
}

type unimplemented struct{ api.StrictUnimplemented }

var _ api.StrictServerInterface = Server{}

// Modules holds the wired modules.
type Modules struct {
	Server   Server
	Identity *identity.Module
	// SMSCapture is set when APP_ENV=test, so e2e tests can read one-time codes.
	SMSCapture *sms.Capture
}

// levelZero answers Level 0 for everyone until the verification module provides levels.
type levelZero struct{}

func (levelZero) GetLevel(context.Context, uuid.UUID) (int, error) { return 0, nil }

// BuildModules wires every module on the infrastructure.
func BuildModules(i *Infra) (*Modules, error) {
	cipher, err := auth.NewCipher(i.Config.DataEncryptionKey)
	if err != nil {
		return nil, err
	}
	m := &Modules{}
	smsSender := smsAdapter(i, m)
	m.Identity = identity.New(identity.Deps{
		Pool: i.Pool, Redis: i.Redis, Keys: i.Keys, Clock: i.Clock, IDs: i.IDs, Log: i.Log,
		Signer: auth.NewSigner(i.Config.JWT.KeyID, i.Config.JWT.SigningKey, 15*time.Minute, i.Clock, i.IDs),
		Cipher: cipher, SMS: smsSender, Levels: levelZero{},
	})
	m.Server = Server{Handler: m.Identity.HTTP}
	return m, nil
}

func smsAdapter(i *Infra, m *Modules) port.SMSSender {
	switch {
	case i.Config.AppEnv == config.EnvTest:
		m.SMSCapture = sms.NewCapture()
		return m.SMSCapture
	case i.Config.SMSAdapter == "sslwireless":
		return sms.SSLWireless{
			Endpoint: "https://smsplus.sslwireless.com/api/v3/send-sms", APIToken: i.Config.SSLWireless.APIToken,
			SID: i.Config.SSLWireless.SID, Client: &http.Client{Timeout: 10 * time.Second}, IDs: i.IDs,
		}
	}
	return sms.Console{Log: i.Log}
}
