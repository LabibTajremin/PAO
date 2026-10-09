package http

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

func items(in []api.BookingItemInput) []app.Item {
	out := make([]app.Item, 0, len(in))
	for _, it := range in {
		out = append(out, app.Item{SubServiceID: it.SubServiceId, Quantity: it.Quantity})
	}
	return out
}

// CreateBooking implements POST /v1/customer/bookings.
func (h *Handler) CreateBooking(ctx context.Context, req api.CreateBookingRequestObject) (api.CreateBookingResponseObject, error) {
	b := req.Body
	in := app.CreateInput{CustomerID: principal(ctx).AccountID, ProviderID: b.ProviderId, ServiceID: b.ServiceId, AddressID: b.AddressId,
		Items: items(b.Items), IdempotencyKey: req.Params.IdempotencyKey}
	if b.Timing == api.TimingScheduled {
		if b.ScheduledAt == nil {
			return nil, errorMap.Map(domain.ErrInvalid)
		}
		in.ScheduledAt = b.ScheduledAt
	}
	if b.Note != nil {
		in.Note = *b.Note
	}
	out, _, err := h.svc.Create(ctx, in)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.CreateBooking201JSONResponse(booking(out, false)), nil
}

// list maps a page of summaries; counterpart is the other side's name.
func list(rows []port.Summary, limit int, asProvider bool) api.BookingList {
	out := api.BookingList{Items: []api.BookingSummary{}}
	for i, r := range rows {
		if i == limit {
			next := httpx.EncodeCursor(httpx.Cursor{CreatedAt: rows[i-1].CreatedAt, ID: rows[i-1].ID})
			out.NextCursor = &next
			break
		}
		counterpart, timing := r.ProviderName, api.TimingAsap
		if asProvider {
			counterpart = r.CustomerName
		}
		if r.Scheduled {
			timing = api.TimingScheduled
		}
		out.Items = append(out.Items, api.BookingSummary{Id: r.ID, Number: app.Number(r.Number), Status: api.BookingStatus(r.Status),
			ServiceName: text(r.ServiceName), CounterpartName: &counterpart, Timing: &timing, ScheduledAt: utc(r.ScheduledAt), Total: r.TotalPaisa,
			CreatedAt: r.CreatedAt.UTC()})
	}
	return out
}

func (h *Handler) list(ctx context.Context, asProvider bool, tab string, cursor *string, limit *int) (api.BookingList, error) {
	cur, err := httpx.DecodeCursor(cursor)
	if err != nil {
		return api.BookingList{}, err
	}
	size := httpx.PageSize(limit)
	p := port.Page{Limit: size + 1}
	if cur != nil {
		p.At, p.ID = &cur.CreatedAt, cur.ID
	}
	rows, err := h.svc.List(ctx, principal(ctx).AccountID, asProvider, tab, p)
	if err != nil {
		return api.BookingList{}, err
	}
	return list(rows, size, asProvider), nil
}

// ListCustomerBookings implements GET /v1/customer/bookings.
func (h *Handler) ListCustomerBookings(ctx context.Context, req api.ListCustomerBookingsRequestObject) (api.ListCustomerBookingsResponseObject, error) {
	out, err := h.list(ctx, false, string(req.Params.Tab), req.Params.Cursor, req.Params.Limit)
	if err != nil {
		return nil, err
	}
	return api.ListCustomerBookings200JSONResponse(out), nil
}

func (h *Handler) mine(ctx context.Context, id uuid.UUID, asProvider bool) (domain.Booking, error) {
	b, err := h.svc.Booking(ctx, principal(ctx).AccountID, id)
	if err == nil && (b.Provider.ID == principal(ctx).AccountID) != asProvider {
		err = domain.ErrNotFound
	}
	return b, errorMap.Map(err)
}

// GetCustomerBooking implements GET /v1/customer/bookings/{bookingId}.
func (h *Handler) GetCustomerBooking(ctx context.Context, req api.GetCustomerBookingRequestObject) (api.GetCustomerBookingResponseObject, error) {
	b, err := h.mine(ctx, req.BookingId, false)
	if err != nil {
		return nil, err
	}
	return api.GetCustomerBooking200JSONResponse(booking(b, false)), nil
}

// GetStartCode implements GET /v1/customer/bookings/{bookingId}/start-code.
func (h *Handler) GetStartCode(ctx context.Context, req api.GetStartCodeRequestObject) (api.GetStartCodeResponseObject, error) {
	code, err := h.svc.StartCode(ctx, principal(ctx).AccountID, req.BookingId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetStartCode200JSONResponse{Code: code}, nil
}

func reason(r string, note *string) string {
	if note != nil && *note != "" {
		return r + ": " + *note
	}
	return r
}

// CancelCustomerBooking implements POST /v1/customer/bookings/{bookingId}/cancel.
func (h *Handler) CancelCustomerBooking(ctx context.Context, req api.CancelCustomerBookingRequestObject) (api.CancelCustomerBookingResponseObject, error) {
	b, err := h.svc.Cancel(ctx, domain.ByCustomer, principal(ctx).AccountID, req.BookingId, reason(string(req.Body.Reason), req.Body.Note))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.CancelCustomerBooking200JSONResponse(booking(b, false)), nil
}

// DecideExtras implements POST /v1/customer/bookings/{bookingId}/extras/decision.
func (h *Handler) DecideExtras(ctx context.Context, req api.DecideExtrasRequestObject) (api.DecideExtrasResponseObject, error) {
	b, err := h.svc.DecideExtras(ctx, principal(ctx).AccountID, req.BookingId, req.Body.ProposalId, req.Body.Approve)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.DecideExtras200JSONResponse(booking(b, false)), nil
}

// GetCustomerReceipt implements GET /v1/customer/bookings/{bookingId}/receipt.
func (h *Handler) GetCustomerReceipt(ctx context.Context, req api.GetCustomerReceiptRequestObject) (api.GetCustomerReceiptResponseObject, error) {
	b, err := h.svc.Receipt(ctx, principal(ctx).AccountID, req.BookingId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetCustomerReceipt200JSONResponse(receipt(b)), nil
}
