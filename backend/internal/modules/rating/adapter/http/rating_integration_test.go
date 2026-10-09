//go:build integration

package http_test

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

func TestRating_BothSidesOnceAfterCompletion(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	open := a.RequestedJob(t, "01712345611", "01812345611")
	if r := a.Do(t, "POST", "/v1/customer/bookings/"+open.ID+"/review", map[string]any{"stars": 5}, open.Customer.Auth()); r.Code(t) != "REVIEW_NOT_ALLOWED" {
		t.Fatalf("review before completion: %s", r.Body)
	}
	j := a.CompletedJob(t, "01712345612", "01812345612")
	review := map[string]any{"stars": 4, "tags": []string{"on_time", "clean"}, "comment": "Quick and tidy"}
	r := a.Do(t, "POST", "/v1/customer/bookings/"+j.ID+"/review", review, j.Customer.Auth())
	if r.Status != 201 || r.JSON(t)["authorName"] != "Nusrat" {
		t.Fatalf("customer review: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/customer/bookings/"+j.ID+"/review", review, j.Customer.Auth()); r.Code(t) != "REVIEW_ALREADY_SUBMITTED" {
		t.Fatalf("second review: %s", r.Body)
	}
	if r := a.Do(t, "POST", "/v1/provider/jobs/"+j.ID+"/review", map[string]any{"stars": 5, "tags": []string{"polite", "paid_promptly"}}, j.Provider.Auth()); r.Status != 201 {
		t.Fatalf("provider review: %d %s", r.Status, r.Body)
	}
	if r := a.Do(t, "POST", "/v1/provider/jobs/"+j.ID+"/review", map[string]any{"stars": 5}, open.Provider.Auth()); r.Code(t) != "REVIEW_NOT_ALLOWED" {
		t.Fatalf("other provider review: %s", r.Body)
	}
	a.RelayEvents(t)
	if r := a.Do(t, "GET", "/v1/provider/rating", nil, j.Provider.Auth()).JSON(t); r["average"] != float64(4) || r["distribution"].(map[string]any)["4"] != float64(1) {
		t.Fatalf("my rating: %v", r)
	}
	if r := a.Do(t, "GET", "/v1/provider/reviews", nil, j.Provider.Auth()).JSON(t); len(r["items"].([]any)) != 1 {
		t.Fatalf("my reviews: %v", r)
	}
	pub := a.Do(t, "GET", "/v1/customer/providers/"+j.Provider.ID.String(), nil, j.Customer.Auth())
	if pub.Status != 200 || pub.JSON(t)["completedJobs"] != float64(1) || pub.JSON(t)["rating"].(map[string]any)["count"] != float64(1) {
		t.Fatalf("public profile: %d %s", pub.Status, pub.Body)
	}
	if r := a.Do(t, "GET", "/v1/customer/providers/"+uuid.NewString(), nil, j.Customer.Auth()); r.Status != 404 {
		t.Fatalf("unknown provider: %d", r.Status)
	}
	cust, err := a.Modules.Rating.Contract.GetCustomerRating(ctx, j.Customer.ID)
	if err != nil || cust.Average != 5 || cust.Count != 1 {
		t.Fatalf("customer rating: %+v %v", cust, err)
	}
	all, err := a.Modules.Rating.Contract.GetProviderRatings(ctx, []uuid.UUID{j.Provider.ID, uuid.New()})
	if err != nil || len(all) != 1 || all[j.Provider.ID].Distribution[3] != 1 {
		t.Fatalf("ratings: %+v %v", all, err)
	}
	if s, _ := a.Modules.Rating.Contract.GetProviderRating(ctx, uuid.New()); s.Count != 0 {
		t.Fatal("unrated provider")
	}
}
