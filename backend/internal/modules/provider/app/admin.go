package app

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
)

// Search lists providers for the admin console with their live online flag (A-05).
func (s *Service) Search(ctx context.Context, q contract.ProviderQuery) ([]contract.ProviderRecord, error) {
	list, err := s.d.Repo.Search(ctx, q)
	for i := range list {
		if err == nil {
			list[i].Online, err = s.d.Presence.IsOnline(ctx, list[i].ID)
		}
	}
	return list, err
}
