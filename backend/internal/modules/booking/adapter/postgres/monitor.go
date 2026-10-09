package postgres

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
)

// Monitor implements port.Repository.
func (r *Repository) Monitor(ctx context.Context, f port.Filter, p port.Page) ([]port.Summary, error) {
	rows, err := r.q.AdminListBookings(ctx, sqlcdb.AdminListBookingsParams{Status: f.Status, ServiceID: f.ServiceID, FromAt: f.From, UntilAt: f.Until,
		Area: f.Area, BeforeAt: p.At, BeforeID: p.ID, MaxRows: int32(p.Limit)}) //nolint:gosec // page size ≤ 101
	out := make([]port.Summary, 0, len(rows))
	for _, row := range rows {
		out = append(out, port.Summary{ID: row.ID, Number: row.Number, Status: row.Status, ServiceName: domain.Text{EN: row.ServiceNameEn, BN: row.ServiceNameBn},
			CustomerName: row.CustomerName, ProviderName: row.ProviderName, Scheduled: row.Timing == "scheduled", ScheduledAt: row.ScheduledAt,
			TotalPaisa: row.TotalPaisa, CreatedAt: row.CreatedAt})
	}
	return out, err
}
