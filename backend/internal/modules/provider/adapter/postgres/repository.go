// Package postgres implements the provider repository on PostGIS.
package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Repository stores the provider schema.
type Repository struct {
	pool   *pgxpool.Pool
	q      *sqlcdb.Queries
	outbox *outbox.Writer
	clock  clock.Clock
}

// New returns the repository.
func New(pool *pgxpool.Pool, w *outbox.Writer, clk clock.Clock) *Repository {
	return &Repository{pool: pool, q: sqlcdb.New(pool), outbox: w, clock: clk}
}

// Ensure implements port.Repository.
func (r *Repository) Ensure(ctx context.Context, id uuid.UUID, phone string, at time.Time) error {
	return r.q.EnsureProvider(ctx, sqlcdb.EnsureProviderParams{ID: id, Phone: phone, CreatedAt: at})
}

// Get implements port.Repository.
func (r *Repository) Get(ctx context.Context, id uuid.UUID) (domain.Provider, error) {
	row, err := r.q.ProviderByID(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Provider{}, domain.ErrNotFound
	}
	return toProvider(row), err
}

func toProvider(r sqlcdb.ProviderByIDRow) domain.Provider {
	p := domain.Provider{ID: r.ID, Phone: r.Phone, FullName: r.FullName, DateOfBirth: r.DateOfBirth, PresentAddress: r.PresentAddress,
		PermanentAddress: r.PermanentAddress, Bio: r.Bio, PhotoMediaID: r.PhotoMediaID, ExperienceYears: int(r.ExperienceYears),
		Language: r.Language, ServiceIDs: r.ServiceIds, WorkingRadiusM: int(r.WorkingRadiusM),
		Emergency:  domain.EmergencyContact{Name: r.EmergencyName, Relation: r.EmergencyRelation, Phone: r.EmergencyPhone, VerifiedAt: r.EmergencyVerifiedAt},
		CoCVersion: r.CocVersion, CoCAcceptedAt: r.CocAcceptedAt, StepsDone: r.StepsDone, SubmittedAt: r.SubmittedAt,
		AccountStatus: r.AccountStatus, Level: int(r.Level), RatingAvg: r.RatingAvg, RatingCount: int(r.RatingCount),
		CompletedJobs: int(r.CompletedJobs), Flagged: r.FlaggedForReview, FlagReason: r.FlagReason, CreatedAt: r.CreatedAt}
	if r.Gender != nil {
		p.Gender = *r.Gender
	}
	if r.HasHomeBase {
		p.HomeBase = &domain.Point{Lat: r.HomeLat, Lng: r.HomeLng}
	}
	return p
}

func saveParams(p domain.Provider, at time.Time) sqlcdb.SaveProfileParams {
	s := sqlcdb.SaveProfileParams{ID: p.ID, FullName: p.FullName, DateOfBirth: p.DateOfBirth, PresentAddress: p.PresentAddress,
		PermanentAddress: p.PermanentAddress, Bio: p.Bio, PhotoMediaID: p.PhotoMediaID, ExperienceYears: int32(p.ExperienceYears), //nolint:gosec // validated ≤ 60
		Language: p.Language, WorkingRadiusM: int32(p.WorkingRadiusM), EmergencyName: p.Emergency.Name, //nolint:gosec // validated ≤ 30 km
		EmergencyRelation: p.Emergency.Relation, EmergencyPhone: p.Emergency.Phone, EmergencyVerifiedAt: p.Emergency.VerifiedAt,
		CocVersion: p.CoCVersion, CocAcceptedAt: p.CoCAcceptedAt, StepsDone: p.StepsDone, SubmittedAt: p.SubmittedAt, UpdatedAt: at}
	if p.Gender != "" {
		s.Gender = &p.Gender
	}
	if p.HomeBase != nil {
		s.HasHomeBase, s.HomeLat, s.HomeLng = true, p.HomeBase.Lat, p.HomeBase.Lng
	}
	return s
}

// Save implements port.Repository.
func (r *Repository) Save(ctx context.Context, p domain.Provider, events ...eventbus.Event) error {
	return db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		q := r.q.WithTx(tx)
		err := q.SaveProfile(ctx, saveParams(p, r.clock.Now()))
		if err == nil {
			err = q.ClearServices(ctx, p.ID)
		}
		for _, s := range p.ServiceIDs {
			if err == nil {
				err = q.AddService(ctx, sqlcdb.AddServiceParams{ProviderID: p.ID, ServiceID: s})
			}
		}
		return r.write(ctx, tx, p.ID, err, events)
	})
}

func (r *Repository) write(ctx context.Context, tx pgx.Tx, id uuid.UUID, err error, events []eventbus.Event) error {
	for _, e := range events {
		if err == nil {
			err = r.outbox.Write(ctx, tx, id.String(), e)
		}
	}
	return err
}

// Publish implements port.Repository.
func (r *Repository) Publish(ctx context.Context, id uuid.UUID, events ...eventbus.Event) error {
	return db.WithTx(ctx, r.pool, func(tx pgx.Tx) error { return r.write(ctx, tx, id, nil, events) })
}

// Candidates implements port.Repository.
func (r *Repository) Candidates(ctx context.Context, ids []uuid.UUID, minLevel int) ([]port.Candidate, error) {
	rows, err := r.q.Candidates(ctx, sqlcdb.CandidatesParams{Ids: ids, MinLevel: int32(minLevel)}) //nolint:gosec // level 0–2
	out := make([]port.Candidate, 0, len(rows))
	for _, c := range rows {
		gender := ""
		if c.Gender != nil {
			gender = *c.Gender
		}
		out = append(out, port.Candidate{WorkingRadiusM: int(c.WorkingRadiusM), Candidate: domain.Candidate{ID: c.ID, Name: c.FullName,
			PhotoMediaID: c.PhotoMediaID, Gender: gender, Level: int(c.Level), Rating: c.RatingAvg, RatingCount: int(c.RatingCount),
			CompletedJobs: int(c.CompletedJobs)}})
	}
	return out, err
}
