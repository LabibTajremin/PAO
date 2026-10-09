package http

import (
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/app"
	audit "github.com/LabibTajremin/PAO/backend/internal/modules/audit/contract"
	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	catalog "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	customer "github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

func providerSummary(r provider.ProviderRecord, services []catalog.Service) api.AdminProviderSummary {
	refs := make([]api.ServiceRef, 0, len(services))
	for _, s := range services {
		refs = append(refs, api.ServiceRef{Id: s.ID, Name: api.LocalizedText{En: s.Name.EN, Bn: s.Name.BN}})
	}
	return api.AdminProviderSummary{Id: r.ID, Name: r.Name, Phone: &r.Phone, Status: api.AccountStatus(r.Status), Level: r.Level, Services: &refs,
		Rating: r.Rating, CompletedJobs: r.CompletedJobs, FlaggedForReview: r.Flagged, Online: &r.Online, CreatedAt: r.CreatedAt}
}

func customerSummary(r customer.CustomerRecord) api.AdminCustomerSummary {
	return api.AdminCustomerSummary{Id: r.ID, Name: r.Name, Phone: &r.Phone, Status: api.AccountStatus(r.Status), Bookings: r.Bookings, CreatedAt: r.CreatedAt}
}

func bookings(list []booking.Summary) []api.BookingSummary {
	out := make([]api.BookingSummary, 0, len(list))
	for _, b := range list {
		out = append(out, api.BookingSummary{Id: b.ID, Number: b.Number, Status: api.BookingStatus(b.Status),
			ServiceName: api.LocalizedText{En: b.ServiceName.EN, Bn: b.ServiceName.BN}, Total: b.TotalPaisa, CreatedAt: b.CreatedAt})
	}
	return out
}

func history(list []audit.Entry) []api.AuditEntry {
	out := make([]api.AuditEntry, 0, len(list))
	for _, e := range list {
		out = append(out, api.AuditEntry{Id: e.ID, At: e.At, ActorId: e.ActorID, ActorRole: &e.ActorRole, Action: e.Action, SubjectType: e.SubjectType,
			SubjectId: e.SubjectID, Reason: &e.Reason, Before: &e.Before, After: &e.After})
	}
	return out
}

func items(list []verification.Item) []api.VerificationItem {
	out := make([]api.VerificationItem, 0, len(list))
	for _, it := range list {
		v := api.VerificationItem{Type: api.ItemType(it.Type), Status: api.ItemStatus(it.Status), Required: it.Required, DecidedAt: it.DecidedAt,
			ExpiresAt: it.ExpiresAt}
		if it.Reason != "" {
			v.RejectionReason = &it.Reason
		}
		out = append(out, v)
	}
	return out
}

func providerDetail(d app.ProviderDetail) api.AdminProviderDetail {
	gender := api.Gender(d.Profile.Gender)
	return api.AdminProviderDetail{Summary: providerSummary(d.Record, d.Services), Gender: &gender, ExperienceYears: &d.Profile.ExperienceYears,
		Items: items(d.Items), RecentBookings: bookings(d.Recent), Complaints: &d.Complaints, Cancellations30d: &d.Cancellations30d,
		StatusHistory: history(d.History)}
}

func customerDetail(d app.CustomerDetail) api.AdminCustomerDetail {
	sum := customerSummary(d.Record)
	if d.Rating.Count > 0 {
		sum.Rating = &d.Rating.Average
	}
	complaints := make([]api.Complaint, 0, len(d.Complaints))
	for _, c := range d.Complaints {
		complaints = append(complaints, toComplaint(c))
	}
	return api.AdminCustomerDetail{Summary: sum, RecentBookings: bookings(d.Recent), Complaints: complaints, StatusHistory: history(d.History)}
}

// page decodes the list cursor; size+1 rows are fetched to detect a next page.
func page(cursor *string, limit *int) (*httpx.Cursor, int, error) {
	cur, err := httpx.DecodeCursor(cursor)
	return cur, httpx.PageSize(limit), err
}
