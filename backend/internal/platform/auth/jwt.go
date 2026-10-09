// Package auth holds the security primitives: EdDSA access tokens with key rotation,
// argon2id hashing, TOTP and secure random values (docs/build/02-architecture.md §5).
package auth

import (
	"crypto"
	"crypto/ed25519"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

// Token errors.
var (
	ErrTokenExpired = errors.New("access token expired")
	ErrTokenInvalid = errors.New("access token invalid")
)

// Claims are the access-token claims.
type Claims struct {
	Subject uuid.UUID
	Roles   []string
	ID      string
	// SessionID names the refresh-token family (device) the token belongs to.
	SessionID uuid.UUID
	Version   int64
	ExpiresAt time.Time
}

type wireClaims struct {
	Roles     []string  `json:"roles"`
	Version   int64     `json:"ver"`
	SessionID uuid.UUID `json:"sid"`
	jwt.RegisteredClaims
}

// Signer issues access tokens with the current key.
type Signer struct {
	keyID string
	key   crypto.Signer
	ttl   time.Duration
	clock clock.Clock
	ids   idgen.Generator
}

// NewSigner returns a signer for an Ed25519 key (crypto.Signer allows a KMS-backed key
// later); ttl is 15 minutes in production.
func NewSigner(keyID string, key crypto.Signer, ttl time.Duration, clk clock.Clock, ids idgen.Generator) *Signer {
	return &Signer{keyID: keyID, key: key, ttl: ttl, clock: clk, ids: ids}
}

// Sign issues a token. c.ID and c.ExpiresAt are filled in; c.Version is the RBAC
// version the roles were read at.
func (s *Signer) Sign(c Claims) (string, Claims, error) {
	now := s.clock.Now()
	c.ID, c.ExpiresAt = s.ids.New().String(), now.Add(s.ttl)
	tok := jwt.NewWithClaims(jwt.SigningMethodEdDSA, wireClaims{
		Roles: c.Roles, Version: c.Version, SessionID: c.SessionID,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject: c.Subject.String(), ID: c.ID, Issuer: "pao",
			IssuedAt: jwt.NewNumericDate(now), ExpiresAt: jwt.NewNumericDate(c.ExpiresAt),
		},
	})
	tok.Header["kid"] = s.keyID
	signed, err := tok.SignedString(s.key)
	if err != nil {
		return "", Claims{}, fmt.Errorf("sign access token: %w", err)
	}
	return signed, c, nil
}

// Verifier checks tokens against the current and previous public keys, so keys can
// rotate without signing everyone out.
type Verifier struct {
	keys  map[string]ed25519.PublicKey
	clock clock.Clock
}

// NewVerifier accepts tokens signed by any of keys (kid → public key).
func NewVerifier(keys map[string]ed25519.PublicKey, clk clock.Clock) *Verifier {
	return &Verifier{keys: keys, clock: clk}
}

// Verify parses and validates a token.
func (v *Verifier) Verify(token string) (Claims, error) {
	var wc wireClaims
	_, err := jwt.ParseWithClaims(token, &wc, v.key,
		jwt.WithValidMethods([]string{jwt.SigningMethodEdDSA.Alg()}),
		jwt.WithIssuer("pao"), jwt.WithExpirationRequired(), jwt.WithTimeFunc(v.clock.Now))
	if errors.Is(err, jwt.ErrTokenExpired) {
		return Claims{}, ErrTokenExpired
	}
	if err != nil {
		return Claims{}, fmt.Errorf("%w: %v", ErrTokenInvalid, err)
	}
	sub, err := uuid.Parse(wc.Subject)
	if err != nil {
		return Claims{}, fmt.Errorf("%w: subject", ErrTokenInvalid)
	}
	return Claims{Subject: sub, Roles: wc.Roles, ID: wc.ID, SessionID: wc.SessionID, Version: wc.Version, ExpiresAt: wc.ExpiresAt.Time}, nil
}

func (v *Verifier) key(t *jwt.Token) (any, error) {
	kid, _ := t.Header["kid"].(string)
	key, ok := v.keys[kid]
	if !ok {
		return nil, fmt.Errorf("unknown key id %q", kid)
	}
	return key, nil
}
