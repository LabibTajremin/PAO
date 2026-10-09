package postgres

import (
	"context"
	"slices"
	"strings"

	"github.com/jackc/pgx/v5"

	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// likeEscaper keeps admin search text literal inside a LIKE pattern.
var likeEscaper = strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)

// Search lists customers for the admin console (A-05).
func (r *Repository) Search(ctx context.Context, q contract.CustomerQuery) ([]contract.CustomerRecord, error) {
	p := sqlcdb.SearchCustomersParams{ID: q.ID, BeforeAt: q.AfterAt, BeforeID: q.AfterID,
		MaxRows: int32(q.Limit)} //nolint:gosec // page sizes are capped at 101 by the caller
	if t := strings.TrimSpace(q.Text); t != "" {
		p.Pattern = "%" + likeEscaper.Replace(strings.ToLower(t)) + "%"
	}
	if q.Status != "" {
		p.Status = &q.Status
	}
	rows, err := r.q.SearchCustomers(ctx, p)
	out := make([]contract.CustomerRecord, 0, len(rows))
	for _, row := range rows {
		out = append(out, contract.CustomerRecord{ID: row.ID, Name: row.Name, Phone: row.Phone, Status: row.AccountStatus,
			Bookings: int(row.Bookings), CreatedAt: row.CreatedAt})
	}
	return out, err
}

// CopyHandlers keep the admin copies (status, booking count) current; each runs in
// the caller's idempotent transaction.
func CopyHandlers() map[string]func(ctx context.Context, tx pgx.Tx, env eventbus.Envelope) error {
	return map[string]func(ctx context.Context, tx pgx.Tx, env eventbus.Envelope) error{
		identity.AccountStatusChanged{}.EventName(): func(ctx context.Context, tx pgx.Tx, env eventbus.Envelope) error {
			e, err := eventbus.Decode[identity.AccountStatusChanged](env)
			if err != nil || !slices.Contains(e.Roles, identity.RoleCustomer) {
				return err
			}
			return sqlcdb.New(tx).SetCustomerStatus(ctx, sqlcdb.SetCustomerStatusParams{ID: e.AccountID, AccountStatus: string(e.To)})
		},
		booking.BookingRequested{}.EventName(): func(ctx context.Context, tx pgx.Tx, env eventbus.Envelope) error {
			e, err := eventbus.Decode[booking.BookingRequested](env)
			if err != nil {
				return err
			}
			return sqlcdb.New(tx).CountCustomerBooking(ctx, e.CustomerID)
		},
	}
}
