// Package port declares what the admin use cases need from adapters.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Repository stores settings and complaints.
type Repository interface {
	ListSettings(ctx context.Context) ([]domain.Setting, error)
	GetSetting(ctx context.Context, key string) (domain.Setting, error)
	// UpdateSetting saves the value and writes the event to the outbox in one transaction.
	UpdateSetting(ctx context.Context, s domain.Setting, e eventbus.Event) error
	CountVerifiedComplaints(ctx context.Context, againstID uuid.UUID) (int, error)
}

// Cache keeps rebuildable reads.
type Cache interface {
	Get(ctx context.Context, key string) ([]byte, bool, error)
	Set(ctx context.Context, key string, value []byte, ttl time.Duration) error
	Delete(ctx context.Context, key string) error
}
