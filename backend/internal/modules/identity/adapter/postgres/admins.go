package postgres

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
)

// AdminByEmail implements port.Repository.
func (r *Repository) AdminByEmail(ctx context.Context, email string) (domain.Admin, error) {
	row, err := r.q.AccountByEmail(ctx, lowerEmail(email))
	if err != nil {
		return domain.Admin{}, notFound(err)
	}
	return r.withCredentials(ctx, toAccount(accountRow(row)))
}

// AdminByID implements port.Repository.
func (r *Repository) AdminByID(ctx context.Context, id uuid.UUID) (domain.Admin, error) {
	a, err := r.AccountByID(ctx, id)
	if err != nil {
		return domain.Admin{}, err
	}
	return r.withCredentials(ctx, a)
}

// ListAdmins implements port.Repository.
func (r *Repository) ListAdmins(ctx context.Context) ([]domain.Admin, error) {
	rows, err := r.q.ListAdmins(ctx)
	out := make([]domain.Admin, 0, len(rows))
	for _, row := range rows {
		a := toAccount(accountRow{ID: row.ID, Phone: row.Phone, Email: row.Email, Name: row.Name, Status: row.Status,
			CreatedAt: row.CreatedAt, DeletedAt: row.DeletedAt, Roles: row.Roles})
		out = append(out, domain.Admin{
			Account: a, PasswordHash: row.PasswordHash, MustChangePassword: row.MustChangePassword,
			TOTPSecretEnc: row.TotpSecretEnc, TOTPEnrolled: row.TotpEnrolled, FailedAttempts: int(row.FailedAttempts),
			LockedUntil: row.LockedUntil, Active: row.Active, LastLoginAt: row.LastLoginAt,
		})
	}
	return out, err
}

func (r *Repository) withCredentials(ctx context.Context, a domain.Account) (domain.Admin, error) {
	c, err := r.q.AdminCredentials(ctx, a.ID)
	if err != nil {
		return domain.Admin{}, notFound(err)
	}
	return domain.Admin{
		Account: a, PasswordHash: c.PasswordHash, MustChangePassword: c.MustChangePassword,
		TOTPSecretEnc: c.TotpSecretEnc, TOTPEnrolled: c.TotpEnrolled, FailedAttempts: int(c.FailedAttempts),
		LockedUntil: c.LockedUntil, Active: c.Active, LastLoginAt: c.LastLoginAt,
	}, nil
}
