package domain

import "time"

// One-time code rules (docs/build/02-architecture.md §5, P03 task 2).
const (
	CodeLength      = 6
	CodeTTL         = 5 * time.Minute
	CodeMaxAttempts = 5
	ResendAfter     = 60 * time.Second
	// SendsPerPhone within SendWindowPhone and SendsPerIP within SendWindowIP throttle
	// SMS cost and brute force.
	SendsPerPhone   = 3
	SendWindowPhone = 15 * time.Minute
	SendsPerIP      = 10
	SendWindowIP    = time.Hour
)

// StoredCode is a sent code as kept in Redis: only its hash and the attempts so far.
type StoredCode struct {
	Hash     string
	Attempts int
}

// CheckAttempt applies a guess: matched says whether the hash matched. It returns
// whether the stored code must now be discarded, and the outcome.
func (c StoredCode) CheckAttempt(matched bool) (discard bool, err error) {
	if matched {
		return true, nil
	}
	if c.Attempts+1 >= CodeMaxAttempts {
		return true, ErrCodeLocked
	}
	return false, ErrCodeInvalid
}
