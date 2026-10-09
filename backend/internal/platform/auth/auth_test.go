package auth

import (
	"crypto/ed25519"
	"crypto/rand"
	"crypto/rsa"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
)

func keyPair(seed byte) (ed25519.PublicKey, ed25519.PrivateKey) {
	s := make([]byte, ed25519.SeedSize)
	s[0] = seed
	priv := ed25519.NewKeyFromSeed(s)
	return priv.Public().(ed25519.PublicKey), priv
}

func TestJWT_SignVerifyAndRotation(t *testing.T) {
	clk := clock.NewFake(time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC))
	oldPub, oldPriv := keyPair(1)
	newPub, newPriv := keyPair(2)
	v := NewVerifier(map[string]ed25519.PublicKey{"k1": oldPub, "k2": newPub}, clk)
	sub := uuid.New()

	for kid, priv := range map[string]ed25519.PrivateKey{"k1": oldPriv, "k2": newPriv} {
		tok, c, err := NewSigner(kid, priv, 15*time.Minute, clk, idgen.V7{}).Sign(sub, []string{"customer"}, 3)
		if err != nil {
			t.Fatal(err)
		}
		got, err := v.Verify(tok)
		if err != nil || got.Subject != sub || got.ID != c.ID || got.Version != 3 || got.Roles[0] != "customer" {
			t.Fatalf("kid %s: %+v %v", kid, got, err)
		}
	}
	tok, _, _ := NewSigner("k2", newPriv, 15*time.Minute, clk, idgen.V7{}).Sign(sub, nil, 1)
	clk.Advance(16 * time.Minute)
	if _, err := v.Verify(tok); !errors.Is(err, ErrTokenExpired) {
		t.Fatalf("expired: %v", err)
	}
}

func TestJWT_RejectsForgedOrMalformedTokens(t *testing.T) {
	clk := clock.NewFake(time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC))
	pub, _ := keyPair(1)
	_, attacker := keyPair(9)
	v := NewVerifier(map[string]ed25519.PublicKey{"k1": pub}, clk)
	forged, _, _ := NewSigner("k1", attacker, time.Minute, clk, idgen.V7{}).Sign(uuid.New(), nil, 1)
	unknownKid, _, _ := NewSigner("k9", attacker, time.Minute, clk, idgen.V7{}).Sign(uuid.New(), nil, 1)
	_, priv := keyPair(1)
	badSub := jwt.NewWithClaims(jwt.SigningMethodEdDSA, jwt.RegisteredClaims{
		Subject: "not-a-uuid", Issuer: "pao", ExpiresAt: jwt.NewNumericDate(clk.Now().Add(time.Minute)),
	})
	badSub.Header["kid"] = "k1"
	badSubTok, _ := badSub.SignedString(priv)
	for name, tok := range map[string]string{"forged": forged, "unknown kid": unknownKid, "garbage": "a.b.c", "bad subject": badSubTok} {
		if _, err := v.Verify(tok); !errors.Is(err, ErrTokenInvalid) {
			t.Errorf("%s: err = %v", name, err)
		}
	}
}

func TestSign_ReportsInvalidKey(t *testing.T) {
	rsaKey, _ := rsa.GenerateKey(rand.Reader, 1024)
	s := NewSigner("k1", rsaKey, time.Minute, clock.System{}, idgen.V7{})
	if _, _, err := s.Sign(uuid.New(), nil, 1); err == nil {
		t.Fatal("signed with a broken key")
	}
}

func TestHash_VerifiesAndRejects(t *testing.T) {
	h := Hash("correct-horse", CodeParams)
	if ok, err := VerifyHash("correct-horse", h); !ok || err != nil {
		t.Fatalf("match: %v %v", ok, err)
	}
	if ok, _ := VerifyHash("wrong", h); ok {
		t.Fatal("wrong secret matched")
	}
	if !strings.HasPrefix(Hash("x", PasswordParams), "$argon2id$v=19$m=65536,t=3,p=2$") {
		t.Fatal("password params not encoded")
	}
	parts := strings.Split(h, "$")
	for _, bad := range []string{"plain", "$bcrypt$x$y$z$w", "$argon2id$v=19$bad$" + parts[4] + "$" + parts[5],
		"$argon2id$v=19$" + parts[3] + "$!!$" + parts[5]} {
		if _, err := VerifyHash("x", bad); !errors.Is(err, ErrHashMalformed) {
			t.Errorf("%q: err = %v", bad, err)
		}
	}
}

func TestRandomValues(t *testing.T) {
	if d := RandomDigits(6); len(d) != 6 || strings.Trim(d, "0123456789") != "" {
		t.Fatalf("digits = %q", d)
	}
	a, b := RandomToken(32), RandomToken(32)
	if a == b || len(a) != 43 {
		t.Fatal("tokens repeat or wrong length")
	}
	if SHA256Hex("a") != "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb" {
		t.Fatal("sha256 mismatch")
	}
}

func TestTOTP(t *testing.T) {
	secret, url, err := NewTOTPSecret("verifier@pao.bd")
	if err != nil || !strings.HasPrefix(url, "otpauth://totp/PAO:verifier@pao.bd") {
		t.Fatalf("secret: %v %s", err, url)
	}
	now := time.Date(2026, 10, 9, 10, 0, 0, 0, time.UTC)
	code, err := TOTPCode(secret, now)
	if err != nil || !ValidateTOTP(code, secret, now.Add(25*time.Second)) {
		t.Fatalf("code %s rejected: %v", code, err)
	}
	if ValidateTOTP(code, secret, now.Add(5*time.Minute)) || ValidateTOTP("000000", "!!", now) {
		t.Fatal("stale or malformed code accepted")
	}
	if _, _, err := NewTOTPSecret(""); err == nil {
		t.Fatal("empty account accepted")
	}
}
