package app

import (
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
)

func TestPublishedTree_CachesPerVersion(t *testing.T) {
	s, repo, cache := newService()
	seedTree(t, s)
	repo.treeHits = 0
	first, err := s.PublishedTree(ctx)
	if err != nil || len(first.Categories) != 1 || first.Categories[0].Services[0].SubServices[0].Price != 50000 {
		t.Fatalf("tree: %+v %v", first, err)
	}
	if _, err := s.PublishedTree(ctx); err != nil || repo.treeHits != 1 {
		t.Fatalf("cache missed: hits=%d", repo.treeHits)
	}
	cache.items["pao:t:cache:catalog:v"+itoa(repo.version)] = []byte("{")
	if _, err := s.PublishedTree(ctx); err != nil || repo.treeHits != 2 {
		t.Fatal("corrupt cache entry not rebuilt")
	}
	cache.getErr, cache.setErr = errBoom, errBoom
	if _, err := s.PublishedTree(ctx); err != nil {
		t.Fatalf("cache failure broke reads: %v", err)
	}
	if all, err := s.AdminTree(ctx); err != nil || len(all.Categories) != 1 {
		t.Fatal("admin tree")
	}
}

func itoa(n int64) string { return string(rune('0' + n)) }

func TestTree_Failures(t *testing.T) {
	for _, f := range []string{"Version", "Tree"} {
		s, repo, _ := newService()
		repo.faults[f] = errBoom
		if _, err := s.PublishedTree(ctx); !errors.Is(err, errBoom) {
			t.Errorf("published %s: %v", f, err)
		}
		if _, err := s.AdminTree(ctx); !errors.Is(err, errBoom) {
			t.Errorf("admin %s: %v", f, err)
		}
		if _, err := s.PublishedService(ctx, uuid.New()); !errors.Is(err, errBoom) {
			t.Errorf("service %s: %v", f, err)
		}
		if _, err := s.ListPublishedServices(ctx); !errors.Is(err, errBoom) {
			t.Errorf("list %s: %v", f, err)
		}
	}
}

func TestPublishedServiceAndSearch(t *testing.T) {
	s, repo, _ := newService()
	_, svc, sub := seedTree(t, s)
	got, err := s.PublishedService(ctx, svc.ID)
	if err != nil || got.ID != svc.ID {
		t.Fatal(err)
	}
	if _, err := s.PublishedService(ctx, uuid.New()); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal("unknown service")
	}
	repo.search = [2][]uuid.UUID{{svc.ID, uuid.New()}, {sub.ID, uuid.New()}}
	services, subs, err := s.Search(ctx, "fan")
	if err != nil || len(services) != 1 || len(subs) != 1 {
		t.Fatalf("search: %v %v %v", services, subs, err)
	}
	repo.faults["Search"] = errBoom
	if _, _, err := s.Search(ctx, "x"); !errors.Is(err, errBoom) {
		t.Fatal("search failure")
	}
	repo.faults = faults{"Version": errBoom}
	repo.search = [2][]uuid.UUID{}
	if _, _, err := s.Search(ctx, "x"); !errors.Is(err, errBoom) {
		t.Fatal("tree failure in search")
	}
	if list, _ := (func() ([]domain.Service, error) { repo.faults = faults{}; return s.ListPublishedServices(ctx) })(); len(list) != 1 {
		t.Fatal("list services")
	}
}

func TestSnapshotAndGetService(t *testing.T) {
	s, _, _ := newService()
	_, svc, sub := seedTree(t, s)
	snap, err := s.Snapshot(ctx, sub.ID)
	if err != nil || snap.Service.ID != svc.ID || snap.SubService.Price != 50000 {
		t.Fatalf("snapshot: %+v %v", snap, err)
	}
	if _, err := s.Snapshot(ctx, uuid.New()); !errors.Is(err, domain.ErrNotFound) {
		t.Fatal("unknown sub-service")
	}
	if got, err := s.GetService(ctx, svc.ID); err != nil || got.ID != svc.ID {
		t.Fatal("get service")
	}
}
