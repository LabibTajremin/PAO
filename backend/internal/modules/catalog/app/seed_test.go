package app

import (
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
)

func seedData(price int64) []SeedCategory {
	return []SeedCategory{{Key: "electrical", Item: domain.Category{Name: name, IconKey: "plug"}, Services: []SeedService{{
		Key:         "electrician",
		Item:        domain.Service{Name: name, IconKey: "bolt", Model: "on_demand", RequiredLevel: 1, SearchRadiusM: 5000},
		SubServices: []SeedSubService{{Key: "fan", Item: domain.SubService{Name: name, Unit: "unit", MaxQuantity: 5}, Price: price}},
	}}}}
}

func TestSeed_IsIdempotentAndVersionsPrices(t *testing.T) {
	s, repo, _ := newService()
	actor := uuid.New()
	for i := 0; i < 2; i++ {
		if err := s.Seed(ctx, seedData(50000), actor); err != nil {
			t.Fatal(err)
		}
	}
	if len(repo.cats) != 1 || len(repo.services) != 1 || len(repo.subs) != 1 || len(repo.prices) != 1 {
		t.Fatalf("duplicates: %d %d %d %d", len(repo.cats), len(repo.services), len(repo.subs), len(repo.prices))
	}
	if err := s.Seed(ctx, seedData(60000), actor); err != nil || len(repo.prices) != 2 {
		t.Fatal("changed price not versioned")
	}
	if SeedID("service", "electrician") != repo.services[SeedID("service", "electrician")].ID {
		t.Fatal("seed IDs not stable")
	}
}

func TestSeed_Failures(t *testing.T) {
	bad := seedData(1)
	bad[0].Services[0].Item.Model = "auction"
	s, _, _ := newService()
	if err := s.Seed(ctx, bad, uuid.New()); !errors.Is(err, domain.ErrInvalid) {
		t.Fatal("invalid service seeded")
	}
	for _, f := range []string{"SaveCategory", "SaveService", "SaveSubService", "AddPrice"} {
		s, repo, _ := newService()
		repo.faults[f] = errBoom
		if err := s.Seed(ctx, seedData(1), uuid.New()); !errors.Is(err, errBoom) {
			t.Errorf("%s not reported", f)
		}
	}
}
