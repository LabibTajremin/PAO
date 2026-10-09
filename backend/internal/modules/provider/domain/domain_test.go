package domain

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestProgress(t *testing.T) {
	steps, complete := Progress(nil)
	if complete || len(steps) != 9 || steps[6].Required {
		t.Fatalf("empty: %+v %v", steps, complete)
	}
	done := []string{}
	for _, s := range Steps {
		if s != "skill_proof" {
			done = WithStep(done, s)
		}
	}
	done = WithStep(done, "personal")
	if _, complete := Progress(done); !complete || len(done) != 8 {
		t.Fatalf("all required: %v", done)
	}
}

func TestPersonalValidate(t *testing.T) {
	today := time.Date(2026, 10, 9, 0, 0, 0, 0, time.UTC)
	ok := Personal{FullName: "Rahim Uddin", DateOfBirth: today.AddDate(-18, 0, 0), Gender: "male", PresentAddress: "Banani 11", PermanentAddress: "Cumilla Sadar"}
	if err := ok.Validate(today); err != nil {
		t.Fatal(err)
	}
	young := ok
	young.DateOfBirth = today.AddDate(-18, 0, 1)
	if !errors.Is(young.Validate(today), ErrTooYoung) {
		t.Fatal("17-year-old accepted")
	}
	bad := ok
	bad.Gender = "x"
	if !errors.Is(bad.Validate(today), ErrInvalid) {
		t.Fatal("bad gender accepted")
	}
}

func TestStepValidators(t *testing.T) {
	if ValidateServices(0, 1) == nil || ValidateServices(6, 1) == nil || ValidateServices(1, 61) == nil || ValidateServices(5, 0) != nil {
		t.Fatal("services")
	}
	dhaka := Point{Lat: 23.8, Lng: 90.4}
	if ValidateArea(dhaka, 999) == nil || ValidateArea(Point{Lat: 90.4, Lng: 23.8}, 5000) == nil || ValidateArea(dhaka, 30000) != nil {
		t.Fatal("area")
	}
	e := EmergencyContact{Name: "Karim", Relation: "Brother", Phone: "+8801712345679"}
	if e.Validate("+8801712345678") != nil || e.Validate(e.Phone) == nil || (EmergencyContact{Name: "K", Relation: "Brother", Phone: "1"}).Validate("") == nil {
		t.Fatal("emergency contact")
	}
}

func TestCanGoOnlineAndBadge(t *testing.T) {
	p := Provider{AccountStatus: "active", Level: 1, HomeBase: &Point{}, ServiceIDs: []uuid.UUID{uuid.New()}}
	if p.CanGoOnline() != nil {
		t.Fatal("verified provider kept offline")
	}
	if (Provider{AccountStatus: "suspended", Level: 2}).CanGoOnline() != ErrNotVerified || (Provider{AccountStatus: "active", Level: 1}).CanGoOnline() != ErrNoServiceArea {
		t.Fatal("gate")
	}
	if Badge(0) != "none" || Badge(1) != "verified" || Badge(2) != "verified_pro" {
		t.Fatal("badge")
	}
}

func TestRank(t *testing.T) {
	near, far, pro := uuid.New(), uuid.New(), uuid.New()
	c := []Candidate{{ID: near, Level: 1, DistanceM: 100, Rating: 4.0}, {ID: far, Level: 1, DistanceM: 900, Rating: 4.9}, {ID: pro, Level: 2, DistanceM: 5000, Rating: 3.9}}
	Rank(c, false)
	if c[0].ID != pro || c[1].ID != near {
		t.Fatalf("distance: %+v", c)
	}
	Rank(c, true)
	if c[0].ID != pro || c[1].ID != far {
		t.Fatalf("rating: %+v", c)
	}
	same := []Candidate{{ID: far, Level: 1, DistanceM: 900, Rating: 4}, {ID: near, Level: 1, DistanceM: 100, Rating: 4}}
	if Rank(same, true); same[0].ID != near {
		t.Fatal("tie on distance")
	}
}

func TestNormalizePhone(t *testing.T) {
	for _, in := range []string{"01712345678", "8801712345678", "+8801712345678", "1712345678"} {
		if got, ok := NormalizePhone(in); !ok || got != "+8801712345678" {
			t.Errorf("%s → %s", in, got)
		}
	}
	for _, in := range []string{"0171234567", "01212345678", "0171234567x"} {
		if _, ok := NormalizePhone(in); ok {
			t.Errorf("%s accepted", in)
		}
	}
}
