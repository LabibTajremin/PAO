package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/port"
)

// seedNamespace derives stable IDs from seed keys, so reseeding updates rows instead of
// duplicating them.
var seedNamespace = uuid.MustParse("6b1f3c7e-2f4a-5d8e-9a0b-1c2d3e4f5a6b")

// SeedID is the stable ID of a seed item, e.g. SeedID("service", "electrician").
func SeedID(kind, key string) uuid.UUID { return uuid.NewSHA1(seedNamespace, []byte(kind+"/"+key)) }

// SeedSubService is a sub-service with its price in paisa.
type SeedSubService struct {
	Key   string
	Item  domain.SubService
	Price int64
}

// SeedService is a service with its sub-services.
type SeedService struct {
	Key         string
	Item        domain.Service
	SubServices []SeedSubService
}

// SeedCategory is a category with its services.
type SeedCategory struct {
	Key      string
	Item     domain.Category
	Services []SeedService
}

// Seed loads the MVP catalog idempotently (P04 task 3). A changed price inserts a new
// version; unchanged prices are left alone.
func (s *Service) Seed(ctx context.Context, cats []SeedCategory, actor uuid.UUID) error {
	return s.change(ctx, func(tx port.TxRepository) error {
		for i, c := range cats {
			c.Item.ID, c.Item.SortOrder, c.Item.Published = SeedID("category", c.Key), i, true
			if err := tx.SaveCategory(ctx, c.Item); err != nil {
				return err
			}
			if err := s.seedServices(ctx, tx, c.Item.ID, c.Services, actor); err != nil {
				return err
			}
		}
		return nil
	})
}

func (s *Service) seedServices(ctx context.Context, tx port.TxRepository, categoryID uuid.UUID, services []SeedService, actor uuid.UUID) error {
	for i, svc := range services {
		svc.Item.ID, svc.Item.CategoryID, svc.Item.SortOrder, svc.Item.Published = SeedID("service", svc.Key), categoryID, i, true
		if err := svc.Item.Validate(); err != nil {
			return err
		}
		if err := tx.SaveService(ctx, svc.Item); err != nil {
			return err
		}
		for j, sub := range svc.SubServices {
			sub.Item.ID, sub.Item.ServiceID, sub.Item.SortOrder, sub.Item.Published = SeedID("sub-service", sub.Key), svc.Item.ID, j, true
			if err := s.seedSubService(ctx, tx, sub, actor); err != nil {
				return err
			}
		}
	}
	return nil
}

func (s *Service) seedSubService(ctx context.Context, tx port.TxRepository, sub SeedSubService, actor uuid.UUID) error {
	if err := tx.SaveSubService(ctx, sub.Item); err != nil {
		return err
	}
	current, err := s.d.Repo.SubService(ctx, sub.Item.ID)
	if err == nil && current.Price == sub.Price {
		return nil
	}
	return tx.AddPrice(ctx, domain.PriceVersion{ID: s.d.IDs.New(), SubServiceID: sub.Item.ID, Amount: sub.Price, EffectiveFrom: s.d.Clock.Now(), CreatedBy: actor})
}
