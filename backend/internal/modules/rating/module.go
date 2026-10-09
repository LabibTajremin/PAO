// Package rating wires the rating module.
package rating

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"

	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/adapter/http"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/adapter/inproc"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/adapter/postgres"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Module is the wired rating module.
type Module struct {
	Service  *app.Service
	HTTP     *http.Handler
	Contract *inproc.Service
}

// New wires the module.
func New(pool *pgxpool.Pool, clk clock.Clock, ids idgen.Generator) *Module {
	svc := app.New(postgres.New(pool, outbox.NewWriter("rating", ids, clk)), clk, ids)
	return &Module{Service: svc, HTTP: http.NewHandler(svc), Contract: inproc.New(svc)}
}

// Subscribe opens completed bookings for review. Adding a reviewable booking twice is a
// no-op, so redelivery is harmless.
func (m *Module) Subscribe(bus *eventbus.Bus) {
	bus.Subscribe(booking.BookingCompleted{}.EventName(), "rating", func(ctx context.Context, env eventbus.Envelope) error {
		e, err := eventbus.Decode[booking.BookingCompleted](env)
		if err != nil {
			return err
		}
		return m.Service.Completed(ctx, domain.Reviewable{BookingID: e.BookingID, CustomerID: e.CustomerID, ProviderID: e.ProviderID,
			CustomerName: e.CustomerName, ProviderName: e.ProviderName, ServiceName: domain.Text(e.ServiceName), CompletedAt: e.At})
	})
}
