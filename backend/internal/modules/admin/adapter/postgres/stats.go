package postgres

import (
	"context"
	"errors"
	"slices"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

type statsHandler func(ctx context.Context, q *sqlcdb.Queries, env eventbus.Envelope) error

func decode[T eventbus.Event](fn func(ctx context.Context, q *sqlcdb.Queries, env eventbus.Envelope, e T) error) statsHandler {
	return func(ctx context.Context, q *sqlcdb.Queries, env eventbus.Envelope) error {
		e, err := eventbus.Decode[T](env)
		if err != nil {
			return err
		}
		return fn(ctx, q, env, e)
	}
}

func bump(requested, completed int32) statsHandler {
	return func(ctx context.Context, q *sqlcdb.Queries, env eventbus.Envelope) error {
		d := env.OccurredAt.In(clock.Dhaka)
		day := time.Date(d.Year(), d.Month(), d.Day(), 0, 0, 0, 0, time.UTC)
		return q.BumpBookings(ctx, sqlcdb.BumpBookingsParams{Day: day, Requested: requested, Completed: completed})
	}
}

// StatsHandlers keep the dashboard read model current from other modules' events (A-09).
func (r *Repository) StatsHandlers() map[string]eventbus.Handler {
	hs := map[string]statsHandler{
		identity.AccountCreated{}.EventName(): decode(func(ctx context.Context, q *sqlcdb.Queries, _ eventbus.Envelope, e identity.AccountCreated) error {
			if e.Role != identity.RoleProvider {
				return nil
			}
			return q.AddStatsProvider(ctx, e.AccountID)
		}),
		identity.AccountStatusChanged{}.EventName(): decode(func(ctx context.Context, q *sqlcdb.Queries, _ eventbus.Envelope, e identity.AccountStatusChanged) error {
			if !slices.Contains(e.Roles, identity.RoleProvider) {
				return nil
			}
			return q.SetStatsStatus(ctx, sqlcdb.SetStatsStatusParams{ProviderID: e.AccountID, Status: string(e.To)})
		}),
		identity.AccountDeleted{}.EventName(): decode(func(ctx context.Context, q *sqlcdb.Queries, _ eventbus.Envelope, e identity.AccountDeleted) error {
			return q.DeleteStatsProvider(ctx, e.AccountID)
		}),
		verification.ProviderLevelChanged{}.EventName(): decode(func(ctx context.Context, q *sqlcdb.Queries, _ eventbus.Envelope, e verification.ProviderLevelChanged) error {
			return q.SetStatsLevel(ctx, sqlcdb.SetStatsLevelParams{ProviderID: e.ProviderID, Level: int32(e.To)}) //nolint:gosec // levels are 0–2
		}),
		booking.BookingRequested{}.EventName(): bump(1, 0),
		booking.BookingCompleted{}.EventName(): bump(0, 1),
	}
	out := make(map[string]eventbus.Handler, len(hs))
	for name, fn := range hs {
		out[name] = outbox.Idempotent(r.pool, "admin", name, func(ctx context.Context, tx pgx.Tx, env eventbus.Envelope) error {
			return fn(ctx, r.q.WithTx(tx), env)
		})
	}
	return out
}

// Dashboard implements port.Repository.
func (r *Repository) Dashboard(ctx context.Context, since time.Time) (domain.Dashboard, []domain.DayCount, error) {
	d := domain.Dashboard{ProvidersByStatus: map[string]int{}, ProvidersByLevel: map[string]int{}}
	statuses, errStatus := r.q.ProvidersByStatus(ctx)
	for _, s := range statuses {
		d.ProvidersByStatus[s.Status] = int(s.N)
	}
	levels, errLevel := r.q.ProvidersByLevel(ctx)
	for _, l := range levels {
		d.ProvidersByLevel[strconv.Itoa(int(l.Level))] = int(l.N)
	}
	rows, errDays := r.q.BookingsSince(ctx, since)
	days := make([]domain.DayCount, 0, len(rows))
	for _, row := range rows {
		days = append(days, domain.DayCount{Date: row.Day, Total: int(row.Requested), Completed: int(row.Completed)})
	}
	open, errOpen := r.q.CountOpenComplaints(ctx)
	d.OpenComplaints = int(open)
	return d, days, errors.Join(errStatus, errLevel, errDays, errOpen)
}
