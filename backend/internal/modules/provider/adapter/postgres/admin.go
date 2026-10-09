package postgres

import (
	"context"
	"strings"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
)

// likeEscaper keeps admin search text literal inside a LIKE pattern.
var likeEscaper = strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)

// Search implements port.Repository.
func (r *Repository) Search(ctx context.Context, q contract.ProviderQuery) ([]contract.ProviderRecord, error) {
	p := sqlcdb.SearchProvidersParams{ID: q.ID, Flagged: q.Flagged, BeforeAt: q.AfterAt, BeforeID: q.AfterID,
		MaxRows: int32(q.Limit)} //nolint:gosec // page sizes are capped at 101 by the caller
	if t := strings.TrimSpace(q.Text); t != "" {
		p.Pattern = "%" + likeEscaper.Replace(strings.ToLower(t)) + "%"
	}
	if q.Status != "" {
		p.Status = &q.Status
	}
	if q.Level != nil {
		l := int32(*q.Level) //nolint:gosec // levels are 0–2
		p.Level = &l
	}
	rows, err := r.q.SearchProviders(ctx, p)
	out := make([]contract.ProviderRecord, 0, len(rows))
	for _, row := range rows {
		out = append(out, contract.ProviderRecord{ID: row.ID, Name: row.FullName, Phone: row.Phone, Status: row.Status, Level: int(row.Level),
			ServiceIDs: row.ServiceIds, Rating: row.RatingAvg, RatingCount: int(row.RatingCount), CompletedJobs: int(row.CompletedJobs),
			Flagged: row.FlaggedForReview, FlagReason: row.FlagReason, CreatedAt: row.CreatedAt})
	}
	return out, err
}
