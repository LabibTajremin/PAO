package httpx

import (
	"encoding/base64"
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// Page sizes (04-decisions.md E7).
const (
	DefaultPageSize = 20
	MaxPageSize     = 100
)

// Cursor marks the last row of a page, ordered by (created_at, id) descending.
type Cursor struct {
	CreatedAt time.Time `json:"t"`
	ID        uuid.UUID `json:"i"`
}

// EncodeCursor returns the opaque cursor string for c.
func EncodeCursor(c Cursor) string {
	raw, _ := json.Marshal(c)
	return base64.RawURLEncoding.EncodeToString(raw)
}

// DecodeCursor parses a cursor; an empty string means the first page. A malformed
// cursor is a validation error.
func DecodeCursor(s *string) (*Cursor, error) {
	if s == nil || *s == "" {
		return nil, nil
	}
	raw, err := base64.RawURLEncoding.DecodeString(*s)
	if err != nil {
		return nil, ErrValidation.WithDetails(map[string]any{"field": "cursor"})
	}
	var c Cursor
	if err := json.Unmarshal(raw, &c); err != nil || c.ID == uuid.Nil {
		return nil, ErrValidation.WithDetails(map[string]any{"field": "cursor"})
	}
	return &c, nil
}

// PageSize returns the requested limit clamped to [1, MaxPageSize].
func PageSize(limit *int) int {
	if limit == nil || *limit < 1 {
		return DefaultPageSize
	}
	return min(*limit, MaxPageSize)
}
