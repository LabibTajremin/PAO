package app

import (
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
)

func TestChangePrice_KeepsHistory(t *testing.T) {
	s, repo, _ := newService()
	_, _, sub := seedTree(t, s)
	before := repo.version
	actor := uuid.New()
	p, err := s.ChangePrice(ctx, sub.ID, 60000, actor)
	if err != nil || p.Amount != 60000 || repo.version != before+1 {
		t.Fatalf("change: %+v %v", p, err)
	}
	hist, err := s.PriceHistory(ctx, sub.ID)
	if err != nil || len(hist) != 2 || hist[0].Amount != 60000 || hist[1].Amount != 50000 {
		t.Fatalf("history: %+v %v", hist, err)
	}
	if ev, ok := repo.events[len(repo.events)-2].(contract.PriceChanged); !ok || ev.ActorID != actor {
		t.Fatalf("event: %+v", repo.events)
	}
	if _, err := s.ChangePrice(ctx, sub.ID, -1, actor); !errors.Is(err, domain.ErrPriceNegative) {
		t.Fatal("negative price")
	}
	if _, err := s.ChangePrice(ctx, uuid.New(), 1, actor); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal("unknown sub-service")
	}
	if _, err := s.PriceHistory(ctx, uuid.New()); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal("unknown history")
	}
	repo.faults["AddPrice"] = errBoom
	if _, err := s.ChangePrice(ctx, sub.ID, 1, actor); !errors.Is(err, errBoom) {
		t.Fatal("add price failure")
	}
}

func TestSave_UpdatesAndValidation(t *testing.T) {
	s, _, _ := newService()
	c, svc, sub := seedTree(t, s)
	c.Published = false
	if _, err := s.SaveCategory(ctx, c); err != nil {
		t.Fatal(err)
	}
	svc.SearchRadiusM = 8000
	if got, err := s.SaveService(ctx, svc); err != nil || got.SearchRadiusM != 8000 {
		t.Fatal(err)
	}
	sub.MaxQuantity = 9
	if got, err := s.UpdateSubService(ctx, sub); err != nil || got.MaxQuantity != 9 || got.Price != 50000 {
		t.Fatalf("update sub: %+v %v", got, err)
	}
	invalid := map[string]error{
		"category":                 second(s.SaveCategory(ctx, domain.Category{})),
		"missing category update":  second(s.SaveCategory(ctx, domain.Category{ID: uuid.New(), Name: name, IconKey: "x"})),
		"service":                  second(s.SaveService(ctx, domain.Service{})),
		"service unknown category": second(s.SaveService(ctx, domain.Service{CategoryID: uuid.New(), Name: name, IconKey: "b", Model: "on_demand", SearchRadiusM: 5000})),
		"missing service update":   second(s.SaveService(ctx, domain.Service{ID: uuid.New(), CategoryID: c.ID, Name: name, IconKey: "b", Model: "on_demand", SearchRadiusM: 5000})),
		"sub":                      second(s.CreateSubService(ctx, domain.SubService{}, 1, uuid.New())),
		"sub price":                second(s.CreateSubService(ctx, domain.SubService{ServiceID: svc.ID, Name: name, Unit: "job", MaxQuantity: 1}, -5, uuid.New())),
		"sub service":              second(s.CreateSubService(ctx, domain.SubService{ServiceID: uuid.New(), Name: name, Unit: "job", MaxQuantity: 1}, 1, uuid.New())),
		"missing sub update":       second(s.UpdateSubService(ctx, domain.SubService{ID: uuid.New(), ServiceID: svc.ID, Name: name, Unit: "job", MaxQuantity: 1})),
		"bad sub update":           second(s.UpdateSubService(ctx, domain.SubService{})),
	}
	for name, err := range invalid {
		if err == nil {
			t.Errorf("%s accepted", name)
		}
	}
}

func second[T any](_ T, err error) error { return err }

func TestSave_StoreFailures(t *testing.T) {
	for _, f := range []string{"InTx", "SaveCategory", "SaveService", "SaveSubService", "BumpVersion", "Publish", "CategoryExists"} {
		s, repo, _ := newService()
		c, svc, sub := seedTree(t, s)
		repo.faults[f] = errBoom
		errs := errors.Join(
			second(s.SaveCategory(ctx, c)),
			second(s.SaveService(ctx, svc)),
			second(s.CreateSubService(ctx, domain.SubService{ServiceID: svc.ID, Name: name, Unit: "job", MaxQuantity: 1}, 1, uuid.New())),
			second(s.UpdateSubService(ctx, sub)),
		)
		if !errors.Is(errs, errBoom) {
			t.Errorf("%s not reported", f)
		}
	}
}
