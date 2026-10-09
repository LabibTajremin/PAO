package domain

import (
	"errors"
	"testing"
)

var name = Name{EN: "Electrician", BN: "ইলেকট্রিশিয়ান"}

func validService() Service {
	return Service{Name: name, IconKey: "bolt", Model: "on_demand", RequiredLevel: 1, SearchRadiusM: 5000}
}

func TestValidate(t *testing.T) {
	if (Category{Name: name, IconKey: "plug"}).Validate() != nil || (Category{Name: Name{EN: "x"}, IconKey: "p"}).Validate() == nil {
		t.Fatal("category validation")
	}
	if err := validService().Validate(); err != nil {
		t.Fatal(err)
	}
	bad := []func(*Service){
		func(s *Service) { s.Model = "auction" },
		func(s *Service) { s.RequiredLevel = 3 },
		func(s *Service) { s.SearchRadiusM = 100 },
		func(s *Service) { s.IconKey = " " },
		func(s *Service) { s.RequiresLevel2 = true },
	}
	for i, mutate := range bad {
		s := validService()
		mutate(&s)
		if !errors.Is(s.Validate(), ErrInvalid) {
			t.Errorf("case %d accepted", i)
		}
	}
	ok := validService()
	ok.RequiresLevel2, ok.RequiredLevel = true, 2
	if ok.Validate() != nil {
		t.Fatal("level 2 service rejected")
	}
	if (SubService{Name: name, Unit: "unit", MaxQuantity: 1}).Validate() != nil ||
		(SubService{Name: name, Unit: "litre", MaxQuantity: 1}).Validate() == nil {
		t.Fatal("sub-service validation")
	}
	if ValidatePrice(0) != nil || !errors.Is(ValidatePrice(-1), ErrPriceNegative) {
		t.Fatal("price validation")
	}
}

func TestBookableAndPublished(t *testing.T) {
	if !validService().Bookable() || (Service{Model: "listing"}).Bookable() {
		t.Fatal("bookable")
	}
	tree := []Category{
		{Published: false},
		{Published: true, Services: []Service{
			{Published: false},
			{Published: true, SubServices: []SubService{{Published: true}, {Published: false}}},
		}},
	}
	got := Published(tree)
	if len(got) != 1 || len(got[0].Services) != 1 || len(got[0].Services[0].SubServices) != 1 || len(tree[1].Services[1].SubServices) != 2 {
		t.Fatalf("published = %+v", got)
	}
}
