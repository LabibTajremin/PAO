//go:build integration

package http_test

import (
	"context"
	"testing"

	"github.com/google/uuid"

	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/notification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
	"github.com/LabibTajremin/PAO/backend/internal/testkit"
)

// TestNotifications_EveryBookingEvent is the event → inbox table test (P08).
func TestNotifications_EveryBookingEvent(t *testing.T) {
	a := testkit.NewAPI(t)
	ctx := context.Background()
	j := a.RequestedJob(t, "01712345651", "01812345651")
	a.Do(t, "PUT", "/v1/provider/profile", map[string]any{"language": "en"}, j.Provider.Auth())
	a.Do(t, "PUT", "/v1/provider/device-token", map[string]string{"token": "broken-provider-device", "platform": "android"}, j.Provider.Auth())
	p := booking.Parties{BookingID: uuid.MustParse(j.ID), CustomerID: j.Customer.ID, ProviderID: j.Provider.ID}
	cases := []struct {
		event    eventbus.Event
		customer string
		provider string
	}{
		{booking.BookingRejected{Parties: p}, "booking_rejected", ""},
		{booking.BookingTimedOut{Parties: p}, "booking_timed_out", "request_missed"},
		{booking.ProviderOnTheWay{Parties: p}, "provider_on_the_way", ""},
		{booking.ProviderArrived{Parties: p}, "provider_arrived", ""},
		{booking.BookingStarted{Parties: p}, "booking_started", ""},
		{booking.ExtraItemsProposed{Parties: p, AddedPaisa: 35000}, "extras_proposed", ""},
		{booking.ExtraItemsDecided{Parties: p, Approved: true}, "", "extras_decided"},
		{booking.ExtraItemsDecided{Parties: p}, "", "extras_decided"},
		{booking.BookingCompleted{Parties: p}, "booking_completed", "booking_completed"},
		{booking.BookingCancelled{Parties: p, By: "customer"}, "", "booking_cancelled"},
		{booking.BookingCancelled{Parties: p, By: "provider"}, "booking_cancelled", ""},
	}
	for _, c := range cases {
		a.Deliver(t, c.event)
		for _, side := range []struct {
			want, path string
			who        testkit.Request
		}{{c.customer, "/v1/customer/notifications?limit=1", j.Customer.Auth()}, {c.provider, "/v1/provider/notifications?limit=1", j.Provider.Auth()}} {
			if side.want == "" {
				continue
			}
			if got := types(inbox(t, a, side.path, side.who)); got[0] != side.want {
				t.Errorf("%s: %v, want %s", c.event.EventName(), got, side.want)
			}
		}
	}
	prov := inbox(t, a, "/v1/provider/notifications?limit=1", j.Provider.Auth())
	if body := prov["items"].([]any)[0].(map[string]any)["body"]; body != "Booking "+a.Do(t, "GET", "/v1/provider/jobs/"+j.ID, nil, j.Provider.Auth()).JSON(t)["number"].(string)+" was cancelled." {
		t.Fatalf("English provider body: %v", body)
	}
	for _, name := range []string{booking.BookingAccepted{}.EventName(), "verification.DocumentExpired", "identity.AccountDeleted"} {
		if err := a.Bus.Dispatch(ctx, eventbus.Envelope{ID: uuid.New(), Name: name, Payload: []byte("{")}); err == nil {
			t.Errorf("%s accepted a broken payload", name)
		}
	}
	before := len(inbox(t, a, "/v1/provider/notifications", j.Provider.Auth())["items"].([]any))
	if err := a.Bus.Dispatch(ctx, a.Envelope(t, booking.BookingAccepted{Parties: booking.Parties{BookingID: uuid.New(), ProviderID: j.Provider.ID}})); err != nil {
		t.Fatalf("unknown booking blocked the outbox: %v", err)
	}
	if after := len(inbox(t, a, "/v1/provider/notifications", j.Provider.Auth())["items"].([]any)); after != before {
		t.Fatal("unknown booking notified")
	}
	stranger := uuid.New()
	if err := a.Modules.Notification.Contract.Send(ctx, contract.Message{RecipientID: stranger, App: "customer", Template: "complaint_resolved",
		Data: map[string]string{"ticket": "1001"}, DedupeKey: "k1"}); err != nil {
		t.Fatal(err)
	}
	if err := a.Modules.Notification.Contract.Send(ctx, contract.Message{RecipientID: stranger, App: "customer", Template: "nope", DedupeKey: "k2"}); err == nil {
		t.Fatal("unknown template sent")
	}
}
