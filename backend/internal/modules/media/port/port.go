// Package port declares what the media use cases need.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	audit "github.com/LabibTajremin/PAO/backend/internal/modules/audit/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/storage"
)

// Repository stores object records.
type Repository interface {
	Create(ctx context.Context, o domain.Object) error
	Get(ctx context.Context, id uuid.UUID) (domain.Object, error)
	MarkConfirmed(ctx context.Context, id uuid.UUID) error
	MarkAttached(ctx context.Context, id uuid.UUID) error
	Delete(ctx context.Context, id uuid.UUID) error
	Orphans(ctx context.Context, createdBefore time.Time) ([]domain.Object, error)
}

// Storage is the object store (platform/storage).
type Storage interface {
	PresignPut(ctx context.Context, bucket, key, contentType string, size int64, ttl time.Duration) (string, map[string]string, error)
	PresignGet(ctx context.Context, bucket, key string, ttl time.Duration) (string, error)
	Head(ctx context.Context, bucket, key string) (storage.ObjectInfo, error)
	Delete(ctx context.Context, bucket, key string) error
}

// Auditor records document views (PRD §6.6).
type Auditor interface {
	Record(ctx context.Context, e audit.Entry) error
}
