// Package port declares what the catalog use cases need.
package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Repository reads the catalog and opens transactions.
type Repository interface {
	// Tree returns every category with its services and sub-services, published or not.
	Tree(ctx context.Context) ([]domain.Category, error)
	CategoryExists(ctx context.Context, id uuid.UUID) (bool, error)
	Service(ctx context.Context, id uuid.UUID) (domain.Service, error)
	SubService(ctx context.Context, id uuid.UUID) (domain.SubService, error)
	PriceHistory(ctx context.Context, subServiceID uuid.UUID) ([]domain.PriceVersion, error)
	Search(ctx context.Context, q string) (serviceIDs, subServiceIDs []uuid.UUID, err error)
	Version(ctx context.Context) (int64, error)
	InTx(ctx context.Context, fn func(tx TxRepository) error) error
}

// TxRepository writes catalog rows inside one transaction.
type TxRepository interface {
	SaveCategory(ctx context.Context, c domain.Category) error
	SaveService(ctx context.Context, s domain.Service) error
	SaveSubService(ctx context.Context, s domain.SubService) error
	// AddPrice inserts an immutable version and makes it current.
	AddPrice(ctx context.Context, p domain.PriceVersion) error
	BumpVersion(ctx context.Context) (int64, error)
	Publish(ctx context.Context, aggregateID string, e eventbus.Event) error
}

// Cache stores rendered catalog trees (cache:catalog:v{version}).
type Cache interface {
	Get(ctx context.Context, key string) ([]byte, bool, error)
	Set(ctx context.Context, key string, value []byte, ttl time.Duration) error
}
