package auth

import (
	"bytes"
	"errors"
	"testing"
)

func TestCipher(t *testing.T) {
	c, err := NewCipher(make([]byte, 32))
	if err != nil {
		t.Fatal(err)
	}
	enc := c.Encrypt([]byte("1234567890"))
	if bytes.Contains(enc, []byte("1234567890")) {
		t.Fatal("plaintext visible")
	}
	if plain, err := c.Decrypt(enc); err != nil || string(plain) != "1234567890" {
		t.Fatalf("decrypt: %q %v", plain, err)
	}
	enc[len(enc)-1] ^= 1
	if _, err := c.Decrypt(enc); !errors.Is(err, ErrCiphertext) {
		t.Fatal("tampered data decrypted")
	}
	if _, err := c.Decrypt([]byte{1}); !errors.Is(err, ErrCiphertext) {
		t.Fatal("short data decrypted")
	}
	h1, h2, h3 := c.LookupHash("a"), c.LookupHash("a"), c.LookupHash("b")
	if h1 != h2 || h1 == h3 {
		t.Fatal("lookup hash not deterministic")
	}
	if _, err := NewCipher([]byte("short")); err == nil {
		t.Fatal("short key accepted")
	}
}
