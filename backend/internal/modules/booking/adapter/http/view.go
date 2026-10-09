package http

import (
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// booking maps a booking for one side; the provider sees the exact address and the
// customer's phone only once they are shared.
func booking(b domain.Booking, asProvider bool) api.Booking {
	open := shared(b)
	timing := api.TimingAsap
	if b.Scheduled {
		timing = api.TimingScheduled
	}
	model := api.ServiceModel(b.ServiceModel)
	out := api.Booking{Id: b.ID, Number: app.Number(b.Number), Status: api.BookingStatus(b.Status), ServiceId: b.ServiceID,
		ServiceName: text(b.ServiceName), ServiceModel: &model, Items: lines(b.Lines), Total: b.TotalPaisa, Timing: timing,
		ScheduledAt: utc(b.ScheduledAt), EndsAt: utc(b.EndsAt), Note: &b.Note, PaymentMethod: api.BookingPaymentMethodCash,
		CashReceived: &b.CashReceived, CreatedAt: b.CreatedAt.UTC(), Provider: party(b.Provider, open), Customer: party(b.Customer, open),
		Address: api.BookingAddress{Area: b.Address.Area}}
	deadline := b.AcceptDeadline.UTC()
	out.AcceptDeadline = &deadline
	if !asProvider || open {
		loc := api.Point{Lat: b.Address.Location.Lat, Lng: b.Address.Location.Lng}
		out.Address.Line1, out.Address.Line2, out.Address.Location = &b.Address.Line1, &b.Address.Line2, &loc
	}
	cancellable := b.Cancellable()
	if asProvider {
		cancellable = domain.CanTransition(b.Status, domain.Cancelled, domain.ByProvider)
	}
	out.Cancellable = &cancellable
	if p := b.Pending(); p != nil {
		out.PendingExtras = &api.ExtrasProposal{Id: p.ID, Items: lines(p.Lines), AddedTotal: p.AddedPaisa, NewTotal: b.TotalPaisa + p.AddedPaisa,
			Status: api.ExtrasProposalStatus(p.Status), ProposedAt: p.ProposedAt.UTC()}
	}
	for _, e := range b.Timeline {
		entry := api.TimelineEntry{Status: api.BookingStatus(e.Status), At: e.At.UTC(), Actor: api.TimelineEntryActor(e.Actor)}
		if e.Reason != "" {
			entry.Reason = &e.Reason
		}
		out.Timeline = append(out.Timeline, entry)
	}
	return out
}

func receipt(b domain.Booking) api.Receipt {
	return api.Receipt{BookingId: b.ID, Number: app.Number(b.Number), CompletedAt: b.CompletedAt.UTC(), ServiceName: text(b.ServiceName),
		ProviderName: b.Provider.Name, CustomerName: b.Customer.Name, Area: &b.Address.Area, Items: lines(b.Lines), Total: b.TotalPaisa,
		PaymentMethod: api.ReceiptPaymentMethodCash}
}
