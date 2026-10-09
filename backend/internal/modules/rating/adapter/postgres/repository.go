// Package postgres implements the rating repository.
package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

// Repository stores the rating schema.
type Repository struct {
	pool   *pgxpool.Pool
	q      *sqlcdb.Queries
	outbox *outbox.Writer
}

// New returns the repository.
func New(pool *pgxpool.Pool, w *outbox.Writer) *Repository {
	return &Repository{pool: pool, q: sqlcdb.New(pool), outbox: w}
}

// AddReviewable implements port.Repository; redelivered events are ignored.
func (r *Repository) AddReviewable(ctx context.Context, b domain.Reviewable) error {
	return r.q.AddReviewable(ctx, sqlcdb.AddReviewableParams{BookingID: b.BookingID, CustomerID: b.CustomerID, ProviderID: b.ProviderID,
		CustomerName: b.CustomerName, ProviderName: b.ProviderName, ServiceNameEn: b.ServiceName.EN, ServiceNameBn: b.ServiceName.BN,
		CompletedAt: b.CompletedAt})
}

// Reviewable implements port.Repository.
func (r *Repository) Reviewable(ctx context.Context, id uuid.UUID) (domain.Reviewable, error) {
	row, err := r.q.ReviewableByID(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		err = domain.ErrNotAllowed
	}
	return domain.Reviewable{BookingID: row.BookingID, CustomerID: row.CustomerID, ProviderID: row.ProviderID, CustomerName: row.CustomerName,
		ProviderName: row.ProviderName, ServiceName: domain.Text{EN: row.ServiceNameEn, BN: row.ServiceNameBn}, CompletedAt: row.CompletedAt}, err
}

func aggregate(count int32, sum int64, s1, s2, s3, s4, s5 int32) domain.Aggregate {
	return domain.Aggregate{Count: int(count), Sum: sum, Distribution: [5]int{int(s1), int(s2), int(s3), int(s4), int(s5)}}
}

// Submit implements port.Repository.
func (r *Repository) Submit(ctx context.Context, rv domain.Review, event func(domain.Aggregate) eventbus.Event) (domain.Aggregate, error) {
	var agg domain.Aggregate
	err := db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		q := r.q.WithTx(tx)
		err := q.InsertReview(ctx, sqlcdb.InsertReviewParams{ID: rv.ID, BookingID: rv.BookingID, AuthorID: rv.AuthorID, AuthorRole: rv.AuthorRole,
			AuthorName: rv.AuthorName, SubjectID: rv.SubjectID, Stars: int32(rv.Stars), Tags: rv.Tags, Comment: rv.Comment, //nolint:gosec // 1–5
			ServiceNameEn: rv.ServiceName.EN, ServiceNameBn: rv.ServiceName.BN, CreatedAt: rv.CreatedAt})
		var row sqlcdb.AddToAggregateRow
		if err == nil {
			row, err = q.AddToAggregate(ctx, sqlcdb.AddToAggregateParams{SubjectID: rv.SubjectID, SubjectRole: rv.SubjectRole(), Stars: int32(rv.Stars)}) //nolint:gosec // 1–5
		}
		agg = aggregate(row.ReviewCount, row.StarSum, row.Stars1, row.Stars2, row.Stars3, row.Stars4, row.Stars5)
		if err == nil {
			err = r.outbox.Write(ctx, tx, rv.SubjectID.String(), event(agg))
		}
		return err
	})
	if db.IsUniqueViolation(err, "") {
		err = domain.ErrAlreadyReviewed
	}
	return agg, err
}

// Aggregates implements port.Repository.
func (r *Repository) Aggregates(ctx context.Context, role string, ids []uuid.UUID) (map[uuid.UUID]domain.Aggregate, error) {
	rows, err := r.q.Aggregates(ctx, sqlcdb.AggregatesParams{SubjectRole: role, Ids: ids})
	out := make(map[uuid.UUID]domain.Aggregate, len(rows))
	for _, row := range rows {
		out[row.SubjectID] = aggregate(row.ReviewCount, row.StarSum, row.Stars1, row.Stars2, row.Stars3, row.Stars4, row.Stars5)
	}
	return out, err
}

// Reviews implements port.Repository.
func (r *Repository) Reviews(ctx context.Context, subject uuid.UUID, authorRole string, p port.Page) ([]domain.Review, error) {
	rows, err := r.q.Reviews(ctx, sqlcdb.ReviewsParams{SubjectID: subject, AuthorRole: authorRole, BeforeAt: p.At, BeforeID: p.ID,
		MaxRows: int32(p.Limit)}) //nolint:gosec // page size ≤ 101
	out := make([]domain.Review, 0, len(rows))
	for _, row := range rows {
		out = append(out, domain.Review{ID: row.ID, BookingID: row.BookingID, AuthorID: row.AuthorID, AuthorRole: row.AuthorRole,
			AuthorName: row.AuthorName, SubjectID: row.SubjectID, Stars: int(row.Stars), Tags: row.Tags, Comment: row.Comment,
			ServiceName: domain.Text{EN: row.ServiceNameEn, BN: row.ServiceNameBn}, CreatedAt: row.CreatedAt})
	}
	return out, err
}
