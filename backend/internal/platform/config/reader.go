package config

import (
	"crypto/ed25519"
	"encoding/base64"
	"fmt"
	"log/slog"
	"slices"
	"strings"
)

// reader collects every problem so start-up reports them all at once.
type reader struct {
	getenv   func(string) string
	problems []string
}

func (r *reader) fail(format string, args ...any) {
	r.problems = append(r.problems, fmt.Sprintf(format, args...))
}

func (r *reader) required(name string) string {
	v := r.getenv(name)
	if v == "" {
		r.fail("%s is required", name)
	}
	return v
}

func (r *reader) optional(name, fallback string) string {
	if v := r.getenv(name); v != "" {
		return v
	}
	return fallback
}

func (r *reader) oneOf(name, fallback string, allowed ...string) string {
	v := r.optional(name, fallback)
	if !slices.Contains(allowed, v) {
		r.fail("%s must be one of %s", name, strings.Join(allowed, ", "))
	}
	return v
}

func (r *reader) level(name string) slog.Level {
	var l slog.Level
	if err := l.UnmarshalText([]byte(r.optional(name, "info"))); err != nil {
		r.fail("%s must be debug, info, warn or error", name)
	}
	return l
}

// key decodes a required base64 secret of exactly size bytes.
func (r *reader) key(name string, size int) []byte {
	raw := r.required(name)
	if raw == "" {
		return nil
	}
	b, err := base64.StdEncoding.DecodeString(raw)
	if err != nil || len(b) != size {
		r.fail("%s must be %d bytes, base64-encoded", name, size)
		return nil
	}
	return b
}

func (r *reader) s3() S3 {
	return S3{
		Endpoint:       r.required("S3_ENDPOINT"),
		PublicEndpoint: r.optional("S3_PUBLIC_ENDPOINT", r.getenv("S3_ENDPOINT")),
		Region:         r.optional("S3_REGION", "us-east-1"),
		AccessKey:      r.required("S3_ACCESS_KEY"),
		SecretKey:      r.required("S3_SECRET_KEY"),
		BucketPrivate:  r.required("S3_BUCKET_PRIVATE"),
		BucketPublic:   r.required("S3_BUCKET_PUBLIC"),
	}
}

func (r *reader) jwt() JWT {
	j := JWT{KeyID: r.optional("JWT_KEY_ID", "k1"), PreviousKeys: map[string]ed25519.PublicKey{}}
	if seed := r.key("JWT_SIGNING_KEY", ed25519.SeedSize); seed != nil {
		j.SigningKey = ed25519.NewKeyFromSeed(seed)
	}
	for _, pair := range strings.Split(r.getenv("JWT_PREVIOUS_PUBLIC_KEYS"), ",") {
		if pair == "" {
			continue
		}
		kid, encoded, _ := strings.Cut(pair, ":")
		pub, err := base64.StdEncoding.DecodeString(encoded)
		if err != nil || len(pub) != ed25519.PublicKeySize || kid == "" {
			r.fail("JWT_PREVIOUS_PUBLIC_KEYS entry %q must be kid:base64-public-key", kid)
			continue
		}
		j.PreviousKeys[kid] = ed25519.PublicKey(pub)
	}
	return j
}
