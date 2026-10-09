package auth

import (
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"

	"golang.org/x/crypto/argon2"
)

// ErrHashMalformed is returned for a stored hash in an unknown format.
var ErrHashMalformed = errors.New("password hash malformed")

// Argon2Params tunes argon2id. Production uses PasswordParams; one-time codes use the
// cheaper CodeParams because they live five minutes and allow five attempts.
type Argon2Params struct {
	Memory  uint32
	Time    uint32
	Threads uint8
}

// Parameter sets.
var (
	PasswordParams = Argon2Params{Memory: 64 * 1024, Time: 3, Threads: 2}
	CodeParams     = Argon2Params{Memory: 8 * 1024, Time: 1, Threads: 1}
)

// Hash returns an encoded argon2id hash of secret with a fresh salt.
func Hash(secret string, p Argon2Params) string {
	salt := RandomBytes(16)
	key := argon2.IDKey([]byte(secret), salt, p.Time, p.Memory, p.Threads, 32)
	return fmt.Sprintf("$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s", argon2.Version, p.Memory, p.Time, p.Threads,
		base64.RawStdEncoding.EncodeToString(salt), base64.RawStdEncoding.EncodeToString(key))
}

// VerifyHash reports whether secret matches encoded, comparing in constant time.
func VerifyHash(secret, encoded string) (bool, error) {
	parts := strings.Split(encoded, "$")
	if len(parts) != 6 || parts[1] != "argon2id" {
		return false, ErrHashMalformed
	}
	var p Argon2Params
	if _, err := fmt.Sscanf(parts[3], "m=%d,t=%d,p=%d", &p.Memory, &p.Time, &p.Threads); err != nil {
		return false, ErrHashMalformed
	}
	salt, err1 := base64.RawStdEncoding.DecodeString(parts[4])
	want, err2 := base64.RawStdEncoding.DecodeString(parts[5])
	if err1 != nil || err2 != nil {
		return false, ErrHashMalformed
	}
	got := argon2.IDKey([]byte(secret), salt, p.Time, p.Memory, p.Threads, uint32(len(want))) //nolint:gosec // length is 32 from Hash
	return subtle.ConstantTimeCompare(got, want) == 1, nil
}
