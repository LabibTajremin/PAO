package domain

import (
	"crypto/subtle"
	"strings"
	"time"

	"github.com/google/uuid"
)

// Token lifetimes (docs/build/02-architecture.md §5).
const (
	AccessTTL  = 15 * time.Minute
	RefreshTTL = 30 * 24 * time.Hour
)

// Family is one signed-in device: a chain of refresh tokens where only the newest is
// valid. Presenting an older one means the chain leaked, so the family is revoked.
type Family struct {
	ID          uuid.UUID
	AccountID   uuid.UUID
	App         string
	CurrentHash string
	AccessJTI   string
	AccessExp   time.Time
}

// FormatRefreshToken joins the family ID and the secret so a refresh can find its family.
func FormatRefreshToken(familyID uuid.UUID, secret string) string {
	return familyID.String() + "." + secret
}

// ParseRefreshToken splits a refresh token into family ID and secret.
func ParseRefreshToken(token string) (uuid.UUID, string, error) {
	id, secret, ok := strings.Cut(token, ".")
	familyID, err := uuid.Parse(id)
	if !ok || err != nil || secret == "" {
		return uuid.Nil, "", ErrRefreshInvalid
	}
	return familyID, secret, nil
}

// Matches compares a presented token hash with the current one in constant time.
func (f Family) Matches(hash string) bool {
	return subtle.ConstantTimeCompare([]byte(f.CurrentHash), []byte(hash)) == 1
}

// ProviderGateScreens are the only partner screens before Level 1 (PRD §8.5).
var ProviderGateScreens = []string{"M01", "M02", "M03", "M04", "M05", "M06", "M07", "M08", "M09", "M10", "M11", "M12", "M13", "M14"}
