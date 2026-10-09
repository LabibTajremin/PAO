package domain

import (
	"errors"
	"strings"
	"testing"

	"github.com/google/uuid"
)

func TestNewReview(t *testing.T) {
	b := Reviewable{BookingID: uuid.New(), CustomerID: uuid.New(), ProviderID: uuid.New(), CustomerName: "Nusrat Jahan", ProviderName: "Rahim Uddin"}
	r, err := NewReview(b, b.CustomerID, Customer, 5, []string{"on_time", "clean"}, "  Great ")
	if err != nil || r.SubjectID != b.ProviderID || r.AuthorName != "Nusrat" || r.Comment != "Great" || r.SubjectRole() != Provider {
		t.Fatalf("customer review: %+v %v", r, err)
	}
	r, err = NewReview(b, b.ProviderID, Provider, 4, nil, "")
	if err != nil || r.SubjectID != b.CustomerID || r.SubjectRole() != Customer || r.Tags == nil {
		t.Fatalf("provider review: %+v %v", r, err)
	}
	if _, err := NewReview(b, uuid.New(), Customer, 5, nil, ""); !errors.Is(err, ErrNotAllowed) {
		t.Fatal("stranger reviewed")
	}
	if _, err := NewReview(b, b.CustomerID, Provider, 5, nil, ""); !errors.Is(err, ErrNotAllowed) {
		t.Fatal("customer posing as provider")
	}
	bad := [][]any{{0, []string(nil), ""}, {6, []string(nil), ""}, {5, []string{"a", "a"}, ""}, {5, []string{"a", "b", "c", "d", "e", "f", "g"}, ""}, {5, []string(nil), strings.Repeat("x", 501)}}
	for _, c := range bad {
		if _, err := NewReview(b, b.CustomerID, Customer, c[0].(int), c[1].([]string), c[2].(string)); !errors.Is(err, ErrInvalid) {
			t.Errorf("%v accepted", c)
		}
	}
	if FirstName("  ") != "" {
		t.Fatal("blank name")
	}
}

func TestAverage(t *testing.T) {
	if (Aggregate{}).Average() != 0 || (Aggregate{Count: 3, Sum: 14}).Average() != 4.7 {
		t.Fatal("average")
	}
}
