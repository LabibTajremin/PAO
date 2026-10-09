// Package port declares what the audit use cases need.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/domain"
)

// Page is a cursor position: entries strictly older than (At, ID).
type Page struct {
	At    *time.Time
	ID    uuid.UUID
	Limit int
}

// Repository appends and reads entries; there is deliberately no update or delete.
type Repository interface {
	Append(ctx context.Context, e domain.Entry) error
	List(ctx context.Context, f domain.Filter, p Page) ([]domain.Entry, error)
}
