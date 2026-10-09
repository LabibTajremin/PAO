package http

import (
	"context"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// dhakaDay is the start of a calendar day in Asia/Dhaka; filter dates are local days.
func dhakaDay(d time.Time, offset int) *time.Time {
	t := time.Date(d.Year(), d.Month(), d.Day()+offset, 0, 0, 0, 0, clock.Dhaka)
	return &t
}

// ListAdminBookings implements GET /v1/admin/bookings.
func (h *Handler) ListAdminBookings(ctx context.Context, req api.ListAdminBookingsRequestObject) (api.ListAdminBookingsResponseObject, error) {
	p := req.Params
	cur, err := httpx.DecodeCursor(p.Cursor)
	if err != nil {
		return nil, err
	}
	size := httpx.PageSize(p.Limit)
	f, page := port.Filter{Status: (*string)(p.Status), ServiceID: p.ServiceId}, port.Page{Limit: size + 1}
	if p.From != nil {
		f.From = dhakaDay(p.From.Time, 0)
	}
	if p.To != nil {
		f.Until = dhakaDay(p.To.Time, 1)
	}
	if p.Area != nil {
		f.Area = *p.Area
	}
	if cur != nil {
		page.At, page.ID = &cur.CreatedAt, cur.ID
	}
	rows, err := h.svc.Monitor(ctx, f, page)
	if err != nil {
		return nil, err
	}
	out := list(rows, size, false)
	for i := range out.Items {
		both := rows[i].CustomerName + " → " + rows[i].ProviderName
		out.Items[i].CounterpartName = &both
	}
	return api.ListAdminBookings200JSONResponse(out), nil
}

// GetAdminBooking implements GET /v1/admin/bookings/{bookingId}; support sees both
// parties' contact details and the full timeline.
func (h *Handler) GetAdminBooking(ctx context.Context, req api.GetAdminBookingRequestObject) (api.GetAdminBookingResponseObject, error) {
	b, err := h.svc.Get(ctx, req.BookingId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	out := booking(b, false)
	out.Provider, out.Customer = party(b.Provider, true), party(b.Customer, true)
	return api.GetAdminBooking200JSONResponse(out), nil
}
