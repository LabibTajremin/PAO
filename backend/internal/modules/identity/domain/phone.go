// Package domain holds the identity rules: phone numbers, account lifecycle, one-time
// codes and refresh-token families. It has no I/O.
package domain

import (
	"regexp"
	"strings"
)

var bdMobile = regexp.MustCompile(`^(?:\+?880|0)?(1[3-9][0-9]{8})$`)

// Phone is a Bangladeshi mobile number in E.164 form (+8801XXXXXXXXX).
type Phone string

// NormalizePhone accepts the common ways people type a Bangladeshi mobile number
// (01712…, 8801712…, +880 1712-…) and returns the E.164 form.
func NormalizePhone(raw string) (Phone, error) {
	cleaned := strings.NewReplacer(" ", "", "-", "", "(", "", ")", "").Replace(strings.TrimSpace(raw))
	m := bdMobile.FindStringSubmatch(cleaned)
	if m == nil {
		return "", ErrInvalidPhone
	}
	return Phone("+880" + m[1]), nil
}

// Masked hides all but the last three digits, for logs and messages.
func (p Phone) Masked() string {
	s := string(p)
	if len(s) < 3 {
		return "***"
	}
	return strings.Repeat("*", len(s)-3) + s[len(s)-3:]
}
