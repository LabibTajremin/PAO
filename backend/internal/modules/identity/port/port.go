// Package port declares what the identity use cases need from the outside world.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/identity/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/auth"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/platform/rbac"
	"github.com/LabibTajremin/PAO/backend/internal/platform/redisx"
)

// Repository reads identity data and opens transactions.
type Repository interface {
	AccountByID(ctx context.Context, id uuid.UUID) (domain.Account, error)
	AccountByPhone(ctx context.Context, phone domain.Phone) (domain.Account, error)
	AdminByEmail(ctx context.Context, email string) (domain.Admin, error)
	AdminByID(ctx context.Context, id uuid.UUID) (domain.Admin, error)
	ListAdmins(ctx context.Context) ([]domain.Admin, error)
	IsPhoneBlocked(ctx context.Context, phone domain.Phone) (bool, error)
	ListRoles(ctx context.Context) ([]string, error)
	LoadGrants(ctx context.Context, role string) (rbac.Grants, error)
	Catalogue(ctx context.Context) (permissions, screens []string, err error)
	InTx(ctx context.Context, fn func(tx TxRepository) error) error
}

// TxRepository writes inside one transaction; Publish adds to the identity outbox.
type TxRepository interface {
	CreateAccount(ctx context.Context, a domain.Account) error
	GrantRole(ctx context.Context, accountID uuid.UUID, role string) error
	SetRoles(ctx context.Context, accountID uuid.UUID, roles []string) error
	UpdateStatus(ctx context.Context, accountID uuid.UUID, status domain.Status) error
	BlockPhone(ctx context.Context, phone domain.Phone, reason string) error
	UnblockPhone(ctx context.Context, phone domain.Phone) error
	AnonymiseAccount(ctx context.Context, accountID uuid.UUID) error
	CreateAdminCredentials(ctx context.Context, accountID uuid.UUID, passwordHash string) error
	SaveAdmin(ctx context.Context, a domain.Admin) error
	ReplaceRole(ctx context.Context, role string, permissions, screens []string) error
	Publish(ctx context.Context, aggregateID string, e eventbus.Event) error
}

// CodeStore keeps hashed one-time codes (otp:{purpose}:{phone}).
type CodeStore interface {
	Save(ctx context.Context, key string, c domain.StoredCode, ttl time.Duration) error
	Get(ctx context.Context, key string) (domain.StoredCode, error)
	IncrementAttempts(ctx context.Context, key string) error
	Delete(ctx context.Context, key string) error
}

// Sessions keeps refresh-token families (rt:{familyID}, sess:{accountID}).
type Sessions interface {
	Save(ctx context.Context, f domain.Family, ttl time.Duration) error
	Get(ctx context.Context, familyID uuid.UUID) (domain.Family, error)
	Delete(ctx context.Context, f domain.Family) error
	ListForAccount(ctx context.Context, accountID uuid.UUID) ([]domain.Family, error)
}

// Challenges keeps pending admin 2FA logins (mfa:{id}).
type Challenges interface {
	Save(ctx context.Context, c domain.Challenge, ttl time.Duration) error
	Get(ctx context.Context, id string) (domain.Challenge, error)
	Delete(ctx context.Context, id string) error
}

// RateLimiter throttles code sends.
type RateLimiter interface {
	Allow(ctx context.Context, key string, limit int, window time.Duration) (redisx.Decision, error)
}

// SMSSender delivers text messages through the configured gateway (D10).
type SMSSender interface {
	Send(ctx context.Context, phone domain.Phone, message string) error
}

// TokenSigner issues access tokens.
type TokenSigner interface {
	Sign(c auth.Claims) (string, auth.Claims, error)
}

// Denylist revokes live access tokens.
type Denylist interface {
	Deny(ctx context.Context, jti string, ttl time.Duration) error
}

// Permissions reads and invalidates the RBAC cache.
type Permissions interface {
	Grants(ctx context.Context, roles []string) (rbac.Grants, error)
	Version(ctx context.Context) (int64, error)
	BumpVersion(ctx context.Context) (int64, error)
}

// LevelReader asks verification for a provider's level (the provider gate, PRD §8.5).
type LevelReader interface {
	GetLevel(ctx context.Context, providerID uuid.UUID) (int, error)
}

// SecretBox encrypts TOTP secrets at rest.
type SecretBox interface {
	Encrypt(plaintext []byte) []byte
	Decrypt(data []byte) ([]byte, error)
}

// Keys builds Redis keys.
type Keys interface {
	Key(parts ...string) string
}
