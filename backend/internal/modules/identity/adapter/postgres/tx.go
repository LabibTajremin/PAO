package postgres

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/outbox"
)

type txRepository struct {
	q      *sqlcdb.Queries
	tx     pgx.Tx
	outbox *outbox.Writer
	clock  clock.Clock
}

func (t *txRepository) CreateAccount(ctx context.Context, a domain.Account) error {
	return t.q.CreateAccount(ctx, sqlcdb.CreateAccountParams{
		ID: a.ID, Phone: optional(string(a.Phone)), Email: optional(lowerEmail(a.Email)), Name: a.Name,
		Status: string(a.Status), CreatedAt: a.CreatedAt,
	})
}

func (t *txRepository) GrantRole(ctx context.Context, id uuid.UUID, role string) error {
	return t.q.GrantRole(ctx, sqlcdb.GrantRoleParams{AccountID: id, Role: role, GrantedAt: t.clock.Now()})
}

func (t *txRepository) SetRoles(ctx context.Context, id uuid.UUID, roles []string) error {
	if err := t.q.RevokeRoles(ctx, id); err != nil {
		return err
	}
	for _, role := range roles {
		if err := t.GrantRole(ctx, id, role); err != nil {
			return err
		}
	}
	return nil
}

func (t *txRepository) UpdateStatus(ctx context.Context, id uuid.UUID, s domain.Status) error {
	return t.q.UpdateStatus(ctx, sqlcdb.UpdateStatusParams{ID: id, Status: string(s), UpdatedAt: t.clock.Now()})
}

func (t *txRepository) BlockPhone(ctx context.Context, p domain.Phone, reason string) error {
	return t.q.BlockPhone(ctx, sqlcdb.BlockPhoneParams{Phone: string(p), Reason: reason, BlockedAt: t.clock.Now()})
}

func (t *txRepository) UnblockPhone(ctx context.Context, p domain.Phone) error {
	return t.q.UnblockPhone(ctx, string(p))
}

func (t *txRepository) AnonymiseAccount(ctx context.Context, id uuid.UUID) error {
	now := t.clock.Now()
	return t.q.AnonymiseAccount(ctx, sqlcdb.AnonymiseAccountParams{ID: id, DeletedAt: &now})
}

func (t *txRepository) CreateAdminCredentials(ctx context.Context, id uuid.UUID, hash string) error {
	return t.q.CreateAdminCredentials(ctx, sqlcdb.CreateAdminCredentialsParams{AccountID: id, PasswordHash: hash})
}

func (t *txRepository) SaveAdmin(ctx context.Context, a domain.Admin) error {
	return t.q.UpdateAdminCredentials(ctx, sqlcdb.UpdateAdminCredentialsParams{
		AccountID: a.ID, PasswordHash: a.PasswordHash, MustChangePassword: a.MustChangePassword,
		TotpSecretEnc: a.TOTPSecretEnc, TotpEnrolled: a.TOTPEnrolled, FailedAttempts: int32(a.FailedAttempts), //nolint:gosec // bounded by AdminMaxFailures
		LockedUntil: a.LockedUntil, Active: a.Active, LastLoginAt: a.LastLoginAt,
	})
}

func (t *txRepository) ReplaceRole(ctx context.Context, role string, perms, screens []string) error {
	if err := t.q.ClearRole(ctx, role); err != nil {
		return err
	}
	for _, p := range perms {
		if err := t.q.AddRolePermission(ctx, sqlcdb.AddRolePermissionParams{Role: role, Permission: p}); err != nil {
			return err
		}
	}
	for _, s := range screens {
		if err := t.q.AddRoleScreen(ctx, sqlcdb.AddRoleScreenParams{Role: role, ScreenID: s}); err != nil {
			return err
		}
	}
	return nil
}

func (t *txRepository) Publish(ctx context.Context, aggregateID string, e eventbus.Event) error {
	return t.outbox.Write(ctx, t.tx, aggregateID, e)
}
