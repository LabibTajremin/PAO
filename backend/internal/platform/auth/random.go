package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"math/big"
	"strings"
)

// RandomBytes returns n bytes from the CSPRNG. crypto/rand never fails on supported
// platforms (Go 1.24+), so there is no error to handle.
func RandomBytes(n int) []byte {
	b := make([]byte, n)
	_, _ = rand.Read(b)
	return b
}

// RandomToken returns a URL-safe token with n bytes of entropy (refresh tokens use 32).
func RandomToken(n int) string {
	return base64.RawURLEncoding.EncodeToString(RandomBytes(n))
}

// RandomDigits returns n decimal digits from the CSPRNG (OTPs, start codes).
func RandomDigits(n int) string {
	var sb strings.Builder
	for range n {
		d, _ := rand.Int(rand.Reader, big.NewInt(10))
		sb.WriteString(d.String())
	}
	return sb.String()
}

// SHA256Hex hashes a high-entropy token for storage; low-entropy secrets use Hash.
func SHA256Hex(s string) string {
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])
}
