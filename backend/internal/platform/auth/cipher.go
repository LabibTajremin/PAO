package auth

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
)

// ErrCiphertext is returned for data that was not produced by this key.
var ErrCiphertext = errors.New("ciphertext invalid")

// Cipher encrypts sensitive fields (NID numbers, TOTP secrets) with AES-256-GCM and
// derives keyed lookup hashes, so equal values can be found without decrypting.
type Cipher struct {
	aead   cipher.AEAD
	macKey []byte
}

// NewCipher builds a cipher from a 32-byte key.
func NewCipher(key []byte) (*Cipher, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, fmt.Errorf("data key: %w", err)
	}
	aead, _ := cipher.NewGCM(block)
	mac := hmac.New(sha256.New, key)
	mac.Write([]byte("pao-lookup-hash"))
	return &Cipher{aead: aead, macKey: mac.Sum(nil)}, nil
}

// Encrypt returns nonce || ciphertext.
func (c *Cipher) Encrypt(plaintext []byte) []byte {
	nonce := RandomBytes(c.aead.NonceSize())
	return c.aead.Seal(nonce, nonce, plaintext, nil)
}

// Decrypt reverses Encrypt.
func (c *Cipher) Decrypt(data []byte) ([]byte, error) {
	n := c.aead.NonceSize()
	if len(data) < n {
		return nil, ErrCiphertext
	}
	plain, err := c.aead.Open(nil, data[:n], data[n:], nil)
	if err != nil {
		return nil, ErrCiphertext
	}
	return plain, nil
}

// LookupHash returns a keyed hash of value for equality lookups.
func (c *Cipher) LookupHash(value string) string {
	mac := hmac.New(sha256.New, c.macKey)
	mac.Write([]byte(value))
	return hex.EncodeToString(mac.Sum(nil))
}
