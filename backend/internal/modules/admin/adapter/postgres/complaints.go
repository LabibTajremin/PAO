package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/db"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

func toComplaint(r sqlcdb.AdminComplaint) domain.Complaint {
	return domain.Complaint{ID: r.ID, Ticket: r.TicketNumber, BookingID: r.BookingID, ReporterID: r.ReporterID, ReporterRole: r.ReporterRole,
		AgainstID: r.AgainstID, Reason: r.Reason, Description: r.Description, Photos: r.PhotoMediaIds, Status: r.Status,
		AssigneeID: r.AssigneeID, Resolution: r.Resolution, Verified: r.Verified, CreatedAt: r.CreatedAt, UpdatedAt: r.UpdatedAt,
		ResolvedAt: r.ResolvedAt}
}

// CreateComplaint implements port.Repository.
func (r *Repository) CreateComplaint(ctx context.Context, c domain.Complaint, event func(domain.Complaint) eventbus.Event) (domain.Complaint, error) {
	err := db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		n, err := r.q.WithTx(tx).InsertComplaint(ctx, sqlcdb.InsertComplaintParams{ID: c.ID, BookingID: c.BookingID, ReporterID: c.ReporterID,
			ReporterRole: c.ReporterRole, AgainstID: c.AgainstID, Reason: c.Reason, Description: c.Description, PhotoMediaIds: c.Photos,
			CreatedAt: c.CreatedAt})
		c.Ticket = n
		if err == nil {
			err = r.outbox.Write(ctx, tx, c.ID.String(), event(c))
		}
		return err
	})
	return c, err
}

// GetComplaint implements port.Repository.
func (r *Repository) GetComplaint(ctx context.Context, id uuid.UUID) (domain.Complaint, error) {
	row, err := r.q.ComplaintByID(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		return domain.Complaint{}, domain.ErrComplaintNotFound
	}
	if err != nil {
		return domain.Complaint{}, err
	}
	c := toComplaint(row)
	comments, err := r.q.ListComments(ctx, id)
	for _, cm := range comments {
		c.Comments = append(c.Comments, domain.Comment(cm))
	}
	return c, err
}

// ListComplaints implements port.Repository.
func (r *Repository) ListComplaints(ctx context.Context, f port.ComplaintFilter) ([]domain.Complaint, error) {
	rows, err := r.q.ListComplaints(ctx, sqlcdb.ListComplaintsParams{Status: f.Status, AssigneeID: f.AssigneeID, BeforeAt: f.At, BeforeID: f.ID,
		MaxRows: int32(f.Limit)}) //nolint:gosec // page sizes are capped at 100 by httpx.PageSize
	out := make([]domain.Complaint, 0, len(rows))
	for _, row := range rows {
		out = append(out, toComplaint(row))
	}
	return out, err
}

// SaveComplaint implements port.Repository.
func (r *Repository) SaveComplaint(ctx context.Context, id uuid.UUID, change func(*domain.Complaint) (eventbus.Event, error)) (domain.Complaint, error) {
	err := db.WithTx(ctx, r.pool, func(tx pgx.Tx) error {
		q := r.q.WithTx(tx)
		row, err := q.LockComplaint(ctx, id)
		if errors.Is(err, pgx.ErrNoRows) {
			err = domain.ErrComplaintNotFound
		}
		if err != nil {
			return err
		}
		c := toComplaint(row)
		e, err := change(&c)
		if err == nil {
			err = q.UpdateComplaint(ctx, sqlcdb.UpdateComplaintParams{ID: id, Status: c.Status, AssigneeID: c.AssigneeID, Resolution: c.Resolution,
				Verified: c.Verified, UpdatedAt: c.UpdatedAt, ResolvedAt: c.ResolvedAt})
		}
		if err == nil && e != nil {
			err = r.outbox.Write(ctx, tx, id.String(), e)
		}
		return err
	})
	if err != nil {
		return domain.Complaint{}, err
	}
	return r.GetComplaint(ctx, id)
}

// AddComment implements port.Repository.
func (r *Repository) AddComment(ctx context.Context, c domain.Comment) error {
	return r.q.InsertComment(ctx, sqlcdb.InsertCommentParams{ID: c.ID, ComplaintID: c.ComplaintID, AuthorID: c.AuthorID, Body: c.Body, At: c.At})
}

// CountComplaintsAgainst implements port.Repository.
func (r *Repository) CountComplaintsAgainst(ctx context.Context, id uuid.UUID) (int, error) {
	n, err := r.q.CountComplaintsAgainst(ctx, id)
	return int(n), err
}

// ComplaintsInvolving implements port.Repository.
func (r *Repository) ComplaintsInvolving(ctx context.Context, id uuid.UUID, limit int) ([]domain.Complaint, error) {
	rows, err := r.q.ComplaintsInvolving(ctx, sqlcdb.ComplaintsInvolvingParams{ReporterID: id,
		Limit: int32(limit)}) //nolint:gosec // callers pass small constants
	out := make([]domain.Complaint, 0, len(rows))
	for _, row := range rows {
		out = append(out, toComplaint(row))
	}
	return out, err
}
