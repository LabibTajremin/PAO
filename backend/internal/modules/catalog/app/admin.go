package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/port"
)

// SaveCategory creates (zero ID) or updates a category (A-02).
func (s *Service) SaveCategory(ctx context.Context, c domain.Category) (domain.Category, error) {
	if err := c.Validate(); err != nil {
		return domain.Category{}, err
	}
	if c.ID == uuid.Nil {
		c.ID = s.d.IDs.New()
	} else if err := s.mustExistCategory(ctx, c.ID); err != nil {
		return domain.Category{}, err
	}
	return c, s.change(ctx, func(tx port.TxRepository) error { return tx.SaveCategory(ctx, c) })
}

// SaveService creates (zero ID) or updates a service in an existing category.
func (s *Service) SaveService(ctx context.Context, svc domain.Service) (domain.Service, error) {
	if err := svc.Validate(); err != nil {
		return domain.Service{}, err
	}
	if err := s.mustExistCategory(ctx, svc.CategoryID); err != nil {
		return domain.Service{}, err
	}
	if svc.ID == uuid.Nil {
		svc.ID = s.d.IDs.New()
	} else if _, err := s.d.Repo.Service(ctx, svc.ID); err != nil {
		return domain.Service{}, err
	}
	if err := s.change(ctx, func(tx port.TxRepository) error { return tx.SaveService(ctx, svc) }); err != nil {
		return domain.Service{}, err
	}
	return s.d.Repo.Service(ctx, svc.ID)
}

// CreateSubService adds a sub-service with its first price.
func (s *Service) CreateSubService(ctx context.Context, sub domain.SubService, price int64, actor uuid.UUID) (domain.SubService, error) {
	if err := s.checkSubService(ctx, sub, price); err != nil {
		return domain.SubService{}, err
	}
	sub.ID = s.d.IDs.New()
	p := domain.PriceVersion{ID: s.d.IDs.New(), SubServiceID: sub.ID, Amount: price, EffectiveFrom: s.d.Clock.Now(), CreatedBy: actor}
	err := s.change(ctx, func(tx port.TxRepository) error {
		if err := tx.SaveSubService(ctx, sub); err != nil {
			return err
		}
		return tx.AddPrice(ctx, p)
	})
	if err != nil {
		return domain.SubService{}, err
	}
	return s.d.Repo.SubService(ctx, sub.ID)
}

// UpdateSubService edits a sub-service; its price changes only through ChangePrice.
func (s *Service) UpdateSubService(ctx context.Context, sub domain.SubService) (domain.SubService, error) {
	if err := s.checkSubService(ctx, sub, 0); err != nil {
		return domain.SubService{}, err
	}
	if _, err := s.d.Repo.SubService(ctx, sub.ID); err != nil {
		return domain.SubService{}, err
	}
	if err := s.change(ctx, func(tx port.TxRepository) error { return tx.SaveSubService(ctx, sub) }); err != nil {
		return domain.SubService{}, err
	}
	return s.d.Repo.SubService(ctx, sub.ID)
}

// ChangePrice inserts a new immutable price version; bookings keep the version they
// copied (PRD §4).
func (s *Service) ChangePrice(ctx context.Context, subID uuid.UUID, amount int64, actor uuid.UUID) (domain.PriceVersion, error) {
	if err := domain.ValidatePrice(amount); err != nil {
		return domain.PriceVersion{}, err
	}
	if _, err := s.d.Repo.SubService(ctx, subID); err != nil {
		return domain.PriceVersion{}, err
	}
	p := domain.PriceVersion{ID: s.d.IDs.New(), SubServiceID: subID, Amount: amount, EffectiveFrom: s.d.Clock.Now(), CreatedBy: actor}
	return p, s.change(ctx, func(tx port.TxRepository) error {
		if err := tx.AddPrice(ctx, p); err != nil {
			return err
		}
		return tx.Publish(ctx, subID.String(), contract.PriceChanged{SubServiceID: subID, PriceVersionID: p.ID, AmountPaisa: amount, ActorID: actor})
	})
}

// PriceHistory lists a sub-service's price versions, newest first.
func (s *Service) PriceHistory(ctx context.Context, subID uuid.UUID) ([]domain.PriceVersion, error) {
	if _, err := s.d.Repo.SubService(ctx, subID); err != nil {
		return nil, err
	}
	return s.d.Repo.PriceHistory(ctx, subID)
}

func (s *Service) checkSubService(ctx context.Context, sub domain.SubService, price int64) error {
	if err := sub.Validate(); err != nil {
		return err
	}
	if err := domain.ValidatePrice(price); err != nil {
		return err
	}
	_, err := s.d.Repo.Service(ctx, sub.ServiceID)
	return err
}

func (s *Service) mustExistCategory(ctx context.Context, id uuid.UUID) error {
	ok, err := s.d.Repo.CategoryExists(ctx, id)
	if err != nil {
		return err
	}
	if !ok {
		return domain.ErrNotFound
	}
	return nil
}

// change runs a write, bumps the catalog version (expiring cached trees) and announces it.
func (s *Service) change(ctx context.Context, write func(tx port.TxRepository) error) error {
	return s.d.Repo.InTx(ctx, func(tx port.TxRepository) error {
		if err := write(tx); err != nil {
			return err
		}
		v, err := tx.BumpVersion(ctx)
		if err != nil {
			return err
		}
		return tx.Publish(ctx, "catalog", contract.CatalogChanged{Version: v})
	})
}
