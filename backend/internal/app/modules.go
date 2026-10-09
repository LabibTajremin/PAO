package app

import (
	"context"
	"net/http"
	"os"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin"
	adminhttp "github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit"
	audithttp "github.com/LabibTajremin/PAO/backend/internal/modules/audit/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking"
	bookinghttp "github.com/LabibTajremin/PAO/backend/internal/modules/booking/adapter/http"
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
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification"
	notificationhttp "github.com/LabibTajremin/PAO/backend/internal/modules/notification/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/adapter/push"
	notifport "github.com/LabibTajremin/PAO/backend/internal/modules/notification/port"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider"
	providerhttp "github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating"
	ratinghttp "github.com/LabibTajremin/PAO/backend/internal/modules/rating/adapter/http"
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
	bookingAPI      = bookinghttp.Handler
	ratingAPI       = ratinghttp.Handler
	notificationAPI = notificationhttp.Handler
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
	*bookingAPI
	*ratingAPI
	*notificationAPI
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
	Booking      *booking.Module
	Rating       *rating.Module
	Notification *notification.Module
	// PushCapture is set unless PUSH_ADAPTER=fcm, so tests can read pushes.
	PushCapture *push.Capture
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
	m.Media = media.New(media.Deps{Pool: i.Pool, Storage: i.Storage, Auditor: m.Audit.Contract, Bucket: i.Config.S3.BucketPrivate, Clock: i.Clock, IDs: i.IDs})
	m.Admin = admin.New(admin.Deps{Pool: i.Pool, Redis: i.Redis, Keys: i.Keys, Clock: i.Clock, IDs: i.IDs, Log: i.Log,
		Media: m.Media.Contract, Identity: m.Identity.Contract})
	m.Customer = customer.New(customer.Deps{Pool: i.Pool, Clock: i.Clock, IDs: i.IDs, Media: m.Media.Contract,
		Identity: m.Identity.Contract, Admin: m.Admin.Contract})
	m.Rating = rating.New(i.Pool, i.Clock, i.IDs)
	m.Provider = provider.New(provider.Deps{Pool: i.Pool, Redis: i.Redis, Keys: i.Keys, Clock: i.Clock, IDs: i.IDs, Log: i.Log,
		Catalog: m.Catalog.Contract, Identity: m.Identity.Contract, Media: m.Media.Contract, Admin: m.Admin.Contract, Rating: m.Rating.Contract})
	m.Verification = verification.New(verification.Deps{Pool: i.Pool, Cipher: cipher, Clock: i.Clock, IDs: i.IDs,
		Provider: m.Provider.Contract, Media: m.Media.Contract, Catalog: m.Catalog.Contract, Admin: m.Admin.Contract})
	m.Booking = booking.New(booking.Deps{Pool: i.Pool, Clock: i.Clock, IDs: i.IDs, Catalog: m.Catalog.Contract, Customer: m.Customer.Contract,
		Identity: m.Identity.Contract, Provider: m.Provider.Contract, Verification: m.Verification.Contract, Media: m.Media.Contract,
		Admin: m.Admin.Contract})
	pusher, err := pushAdapter(i, m)
	if err != nil {
		return nil, err
	}
	m.Admin.Connect(admin.Late{Booking: m.Booking.Contract, Verification: m.Verification.Contract, Provider: m.Provider.Contract,
		Customer: m.Customer.Contract, Rating: m.Rating.Contract, Audit: m.Audit.Contract, Catalog: m.Catalog.Contract})
	m.Notification = notification.New(notification.Deps{Pool: i.Pool, Pusher: pusher, Clock: i.Clock, IDs: i.IDs, Log: i.Log,
		Customer: m.Customer.Contract, Provider: m.Provider.Contract, Booking: m.Booking.Contract})
	m.Server = Server{identityAPI: m.Identity.HTTP, catalogAPI: m.Catalog.HTTP, auditAPI: m.Audit.HTTP, mediaAPI: m.Media.HTTP, adminAPI: m.Admin.HTTP,
		customerAPI: m.Customer.HTTP, providerAPI: m.Provider.HTTP,
		verificationAPI: m.Verification.HTTP, bookingAPI: m.Booking.HTTP,
		ratingAPI: m.Rating.HTTP, notificationAPI: m.Notification.HTTP}
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
	m.Admin.Subscribe(bus)
	m.Customer.Subscribe(bus)
	m.Provider.Subscribe(bus)
	m.Verification.Subscribe(bus)
	m.Rating.Subscribe(bus)
	m.Notification.Subscribe(bus)
}

// RegisterJobs adds every module's background jobs (worker process).
func (m *Modules) RegisterJobs(r *jobs.Registry) {
	m.Media.RegisterJobs(r)
	m.Provider.RegisterJobs(r)
	m.Verification.RegisterJobs(r)
	m.Booking.RegisterJobs(r)
}

func pushAdapter(i *Infra, m *Modules) (notifport.Pusher, error) {
	if i.Config.PushAdapter == "fcm" {
		creds, err := os.ReadFile(i.Config.FCMCredentialsFile)
		if err != nil {
			return nil, err
		}
		return push.NewFCM(context.Background(), creds)
	}
	m.PushCapture = push.NewCapture(i.Log)
	return m.PushCapture, nil
}
