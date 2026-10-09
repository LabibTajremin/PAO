package postgres

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/port"
	rating "github.com/LabibTajremin/PAO/backend/internal/modules/rating/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Offline takes a provider out of presence.
type Offline func(ctx context.Context, id uuid.UUID, reason string) error

// Handlers keep the read-model copies (level, status, rating, jobs) current and flag
// providers for review when quality thresholds are crossed (PRD §6.4, D13).
type Handlers struct {
	repo     *Repository
	settings port.Settings
	offline  Offline
}

// NewHandlers returns the event handlers.
func NewHandlers(repo *Repository, settings port.Settings, offline Offline) *Handlers {
	return &Handlers{repo: repo, settings: settings, offline: offline}
}

type txHandler func(ctx context.Context, q *sqlcdb.Queries, tx pgx.Tx, env eventbus.Envelope) error

// Map returns the handlers by event name, each applied once per event.
func (h *Handlers) Map() map[string]eventbus.Handler {
	hs := map[string]txHandler{
		verification.ProviderLevelChanged{}.EventName(): h.onLevel,
		identity.AccountStatusChanged{}.EventName():     h.onStatus,
		identity.AccountDeleted{}.EventName():           h.onDeleted,
		rating.ReviewSubmitted{}.EventName():            h.onReview,
		booking.BookingCompleted{}.EventName():          h.onCompleted,
		booking.BookingCancelled{}.EventName():          h.onCancelled,
		admin.ComplaintResolved{}.EventName():           h.onComplaint,
	}
	out := make(map[string]eventbus.Handler, len(hs))
	for name, fn := range hs {
		out[name] = outbox.Idempotent(h.repo.pool, "provider", name, func(ctx context.Context, tx pgx.Tx, env eventbus.Envelope) error {
			return fn(ctx, h.repo.q.WithTx(tx), tx, env)
		})
	}
	return out
}

func (h *Handlers) onLevel(ctx context.Context, q *sqlcdb.Queries, _ pgx.Tx, env eventbus.Envelope) error {
	e, err := eventbus.Decode[verification.ProviderLevelChanged](env)
	if err == nil {
		err = q.SetLevel(ctx, sqlcdb.SetLevelParams{ID: e.ProviderID, Level: int32(e.To)}) //nolint:gosec // level 0–2
	}
	if err == nil && e.To < 1 {
		err = h.offline(ctx, e.ProviderID, "level_dropped")
	}
	return err
}

func (h *Handlers) onStatus(ctx context.Context, q *sqlcdb.Queries, _ pgx.Tx, env eventbus.Envelope) error {
	e, err := eventbus.Decode[identity.AccountStatusChanged](env)
	if err == nil {
		err = q.SetAccountStatus(ctx, sqlcdb.SetAccountStatusParams{ID: e.AccountID, AccountStatus: string(e.To)})
	}
	if err == nil && e.To != identity.StatusActive {
		err = h.offline(ctx, e.AccountID, "account_"+string(e.To))
	}
	return err
}

func (h *Handlers) onDeleted(ctx context.Context, q *sqlcdb.Queries, _ pgx.Tx, env eventbus.Envelope) error {
	e, err := eventbus.Decode[identity.AccountDeleted](env)
	if err == nil {
		err = h.offline(ctx, e.AccountID, "account_deleted")
	}
	if err == nil {
		err = q.DeleteProvider(ctx, e.AccountID)
	}
	return err
}

func (h *Handlers) flag(ctx context.Context, q *sqlcdb.Queries, tx pgx.Tx, id uuid.UUID, reason string) error {
	n, err := q.Flag(ctx, sqlcdb.FlagParams{ID: id, FlagReason: reason})
	if err == nil && n == 1 {
		err = h.repo.outbox.Write(ctx, tx, id.String(), contract.ProviderFlaggedForReview{ProviderID: id, Reason: reason})
	}
	return err
}

func (h *Handlers) onReview(ctx context.Context, q *sqlcdb.Queries, tx pgx.Tx, env eventbus.Envelope) error {
	e, err := eventbus.Decode[rating.ReviewSubmitted](env)
	if err != nil || e.SubjectRole != "provider" {
		return err
	}
	_, err = q.SetRating(ctx, sqlcdb.SetRatingParams{ID: e.SubjectID, RatingAvg: e.NewAverage, RatingCount: int32(e.NewCount)}) //nolint:gosec // review counts are small
	var t port.Quality
	if err == nil {
		t, err = h.settings.Quality(ctx)
	}
	if err == nil && e.NewCount >= t.RatingMinJobs && e.NewAverage < t.RatingFloor {
		err = h.flag(ctx, q, tx, e.SubjectID, "rating_below_floor")
	}
	return err
}

func (h *Handlers) onCompleted(ctx context.Context, q *sqlcdb.Queries, _ pgx.Tx, env eventbus.Envelope) error {
	e, err := eventbus.Decode[booking.BookingCompleted](env)
	if err == nil {
		err = q.AddCompletedJob(ctx, e.ProviderID)
	}
	return err
}

func (h *Handlers) onCancelled(ctx context.Context, q *sqlcdb.Queries, tx pgx.Tx, env eventbus.Envelope) error {
	e, err := eventbus.Decode[booking.BookingCancelled](env)
	if err != nil || e.By != "provider" || !e.AfterAcceptance {
		return err
	}
	err = q.AddCancellation(ctx, sqlcdb.AddCancellationParams{BookingID: e.BookingID, ProviderID: e.ProviderID, At: env.OccurredAt})
	var n int64
	if err == nil {
		n, err = q.CountCancellations(ctx, sqlcdb.CountCancellationsParams{ProviderID: e.ProviderID, At: env.OccurredAt.Add(-30 * 24 * time.Hour)})
	}
	var t port.Quality
	if err == nil {
		t, err = h.settings.Quality(ctx)
	}
	if err == nil && n >= int64(t.MaxCancellations) {
		err = h.flag(ctx, q, tx, e.ProviderID, "cancellations")
	}
	return err
}

func (h *Handlers) onComplaint(ctx context.Context, q *sqlcdb.Queries, tx pgx.Tx, env eventbus.Envelope) error {
	e, err := eventbus.Decode[admin.ComplaintResolved](env)
	if err != nil || !e.Verified {
		return err
	}
	return h.flag(ctx, q, tx, e.AgainstID, "verified_complaint")
}
