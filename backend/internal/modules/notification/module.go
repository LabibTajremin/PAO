// Package notification wires the notification module.
package notification

import (
	"log/slog"

	"github.com/jackc/pgx/v5/pgxpool"

	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	customer "github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/adapter/peers"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/port"
	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Deps are the shared services and peer contracts the module needs.
type Deps struct {
	Pool     *pgxpool.Pool
	Pusher   port.Pusher
	Clock    clock.Clock
	IDs      idgen.Generator
	Log      *slog.Logger
	Customer customer.CustomerService
	Provider provider.ProviderService
	Booking  booking.BookingService
}

// Module is the wired notification module.
type Module struct {
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
}

// New wires the module.
func New(d Deps) *Module {
	svc := app.New(app.Deps{Repo: postgres.New(d.Pool), Pusher: d.Pusher, Languages: peers.Languages{Customers: d.Customer, Providers: d.Provider},
		Bookings: peers.Bookings{Svc: d.Booking}, Clock: d.Clock, IDs: d.IDs, Log: d.Log})
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc)}
}

// Subscribe registers a handler for every event that notifies someone. Inbox rows are
// unique per event and recipient, so redelivery neither duplicates nor re-pushes.
func (m *Module) Subscribe(bus *eventbus.Bus) {
	for name, h := range m.Service.Handlers() {
		bus.Subscribe(name, "notification", h)
	}
}
