package app

import (
	"context"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin"
	adminhttp "github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit"
	audithttp "github.com/LabibTajremin/PAO/backend/internal/modules/audit/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog"
	cataloghttp "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer"
	customerhttp "github.com/LabibTajremin/PAO/backend/internal/modules/customer/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity"
	identityhttp "github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/sms"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/port"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media"
	mediahttp "github.com/LabibTajremin/PAO/backend/internal/modules/media/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider"
	providerhttp "github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification"
	verificationhttp "github.com/LabibTajremin/PAO/backend/internal/modules/verification/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/config"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
	"github.com/LabibTajremin/PAO/backend/internal/platform/jobs"
)

// Aliases give each module's handler a distinct embedded field name.
type (
	identityAPI     = identityhttp.Handler
	catalogAPI      = cataloghttp.Handler
	auditAPI        = audithttp.Handler
	mediaAPI        = mediahttp.Handler
	adminAPI        = adminhttp.Handler
	customerAPI     = customerhttp.Handler
	providerAPI     = providerhttp.Handler
	verificationAPI = verificationhttp.Handler
)

// Server serves every API operation. Each module's handler is embedded at depth one;
// operations no module implements yet fall through to the depth-two fallback.
type Server struct {
	*identityAPI
	*catalogAPI
	*auditAPI
	*mediaAPI
	*adminAPI
	*customerAPI
	*providerAPI
	*verificationAPI
	unimplemented
}

type unimplemented struct{ api.StrictUnimplemented }

var _ api.StrictServerInterface = Server{}

// Modules holds the wired modules.
type Modules struct {
	Server   Server
	Identity *identity.Module
	Catalog  *catalog.Module
	Audit    *audit.Module
	Media    *media.Module
	Admin    *admin.Module
	Customer *customer.Module
	Provider *provider.Module
	// Verification is built last: it reads providers, media, catalog and settings.
	Verification *verification.Module
	// SMSCapture is set when APP_ENV=test, so e2e tests can read one-time codes.
	SMSCapture *sms.Capture
}

// levels lets identity's provider gate read levels from verification, which is built
// after identity because it depends on modules that depend on identity.
type levels struct{ m *Modules }

func (l levels) GetLevel(ctx context.Context, id uuid.UUID) (int, error) {
	return l.m.Verification.Contract.GetLevel(ctx, id)
}

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
		Cipher: cipher, SMS: smsSender, Levels: levels{m},
	})
	m.Catalog = catalog.New(catalog.Deps{Pool: i.Pool, Redis: i.Redis, Keys: i.Keys, Clock: i.Clock, IDs: i.IDs, Log: i.Log})
	m.Audit = audit.New(i.Pool, i.Clock, i.IDs)
	m.Admin = admin.New(admin.Deps{Pool: i.Pool, Redis: i.Redis, Keys: i.Keys, Clock: i.Clock, IDs: i.IDs, Log: i.Log})
	m.Media = media.New(media.Deps{Pool: i.Pool, Storage: i.Storage, Auditor: m.Audit.Contract, Bucket: i.Config.S3.BucketPrivate, Clock: i.Clock, IDs: i.IDs})
	m.Customer = customer.New(customer.Deps{Pool: i.Pool, Clock: i.Clock, IDs: i.IDs, Media: m.Media.Contract,
		Identity: m.Identity.Contract, Admin: m.Admin.Contract})
	m.Provider = provider.New(provider.Deps{Pool: i.Pool, Redis: i.Redis, Keys: i.Keys, Clock: i.Clock, IDs: i.IDs, Log: i.Log,
		Catalog: m.Catalog.Contract, Identity: m.Identity.Contract, Media: m.Media.Contract, Admin: m.Admin.Contract})
	m.Verification = verification.New(verification.Deps{Pool: i.Pool, Cipher: cipher, Clock: i.Clock, IDs: i.IDs,
		Provider: m.Provider.Contract, Media: m.Media.Contract, Catalog: m.Catalog.Contract, Admin: m.Admin.Contract})
	m.Server = Server{identityAPI: m.Identity.HTTP, catalogAPI: m.Catalog.HTTP, auditAPI: m.Audit.HTTP, mediaAPI: m.Media.HTTP, adminAPI: m.Admin.HTTP,
		customerAPI: m.Customer.HTTP, providerAPI: m.Provider.HTTP,
		verificationAPI: m.Verification.HTTP}
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

// Subscribe registers every module's event handlers on the bus (worker process).
func (m *Modules) Subscribe(bus *eventbus.Bus) {
	m.Audit.Subscribe(bus)
	m.Customer.Subscribe(bus)
	m.Provider.Subscribe(bus)
	m.Verification.Subscribe(bus)
}

// RegisterJobs adds every module's background jobs (worker process).
func (m *Modules) RegisterJobs(r *jobs.Registry) {
	m.Media.RegisterJobs(r)
	m.Provider.RegisterJobs(r)
	m.Verification.RegisterJobs(r)
}
