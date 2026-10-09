// Package postgres implements the append-only audit repository.
package postgres

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/port"
)

// Repository writes and reads audit.entries. It has no update or delete method, and the
// table's triggers reject them anyway.
type Repository struct{ q *sqlcdb.Queries }

// New returns the repository.
func New(pool *pgxpool.Pool) *Repository { return &Repository{q: sqlcdb.New(pool)} }

func jsonOrNil(m map[string]any) []byte {
	if m == nil {
		return nil
	}
	raw, _ := json.Marshal(m)
	return raw
}

func optional(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

// Append implements port.Repository; an entry for an already audited event is skipped.
func (r *Repository) Append(ctx context.Context, e domain.Entry) error {
	return r.q.AppendEntry(ctx, sqlcdb.AppendEntryParams{
		ID: e.ID, At: e.At, ActorID: e.ActorID, ActorRole: e.ActorRole, Action: e.Action, SubjectType: e.SubjectType,
		SubjectID: e.SubjectID, Reason: e.Reason, Before: jsonOrNil(e.Before), After: jsonOrNil(e.After), EventID: e.EventID,
	})
}

// List implements port.Repository.
func (r *Repository) List(ctx context.Context, f domain.Filter, p port.Page) ([]domain.Entry, error) {
	params := sqlcdb.ListParams{
		ActorID: f.ActorID, Action: optional(f.Action), SubjectType: optional(f.SubjectType), SubjectID: optional(f.SubjectID),
		FromAt: f.From, ToAt: f.To, CursorAt: p.At, PageSize: int32(p.Limit), //nolint:gosec // page size is clamped to 100
	}
	if p.At != nil {
		params.CursorID = &p.ID
	}
	rows, err := r.q.List(ctx, params)
	out := make([]domain.Entry, 0, len(rows))
	for _, row := range rows {
		e := domain.Entry{ID: row.ID, At: row.At, ActorID: row.ActorID, ActorRole: row.ActorRole, Action: row.Action,
			SubjectType: row.SubjectType, SubjectID: row.SubjectID, Reason: row.Reason}
		_ = json.Unmarshal(row.Before, &e.Before)
		_ = json.Unmarshal(row.After, &e.After)
		out = append(out, e)
	}
	return out, err
}
