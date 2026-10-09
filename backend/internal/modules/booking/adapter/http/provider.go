package http

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// job maps a provider-side result.
func job(b domain.Booking, err error) (api.Booking, error) {
	if err != nil {
		return api.Booking{}, errorMap.Map(err)
	}
	return booking(b, true), nil
}

func me(ctx context.Context) uuid.UUID { return principal(ctx).AccountID }

// ListProviderJobs implements GET /v1/provider/jobs.
func (h *Handler) ListProviderJobs(ctx context.Context, req api.ListProviderJobsRequestObject) (api.ListProviderJobsResponseObject, error) {
	out, err := h.list(ctx, true, string(req.Params.Tab), req.Params.Cursor, req.Params.Limit)
	if err != nil {
		return nil, err
	}
	return api.ListProviderJobs200JSONResponse(out), nil
}

// GetProviderJob implements GET /v1/provider/jobs/{bookingId}.
func (h *Handler) GetProviderJob(ctx context.Context, req api.GetProviderJobRequestObject) (api.GetProviderJobResponseObject, error) {
	b, err := job(h.mine(ctx, req.BookingId, true))
	if err != nil {
		return nil, err
	}
	return api.GetProviderJob200JSONResponse(b), nil
}

// AcceptRequest implements POST /v1/provider/jobs/{bookingId}/accept.
func (h *Handler) AcceptRequest(ctx context.Context, req api.AcceptRequestRequestObject) (api.AcceptRequestResponseObject, error) {
	b, err := job(h.svc.Accept(ctx, me(ctx), req.BookingId))
	if err != nil {
		return nil, err
	}
	return api.AcceptRequest200JSONResponse(b), nil
}

// RejectRequest implements POST /v1/provider/jobs/{bookingId}/reject.
func (h *Handler) RejectRequest(ctx context.Context, req api.RejectRequestRequestObject) (api.RejectRequestResponseObject, error) {
	b, err := job(h.svc.Reject(ctx, me(ctx), req.BookingId, reason(string(req.Body.Reason), req.Body.Note)))
	if err != nil {
		return nil, err
	}
	return api.RejectRequest200JSONResponse(b), nil
}

// MarkOnTheWay implements POST /v1/provider/jobs/{bookingId}/on-the-way.
func (h *Handler) MarkOnTheWay(ctx context.Context, req api.MarkOnTheWayRequestObject) (api.MarkOnTheWayResponseObject, error) {
	b, err := job(h.svc.Advance(ctx, me(ctx), req.BookingId, domain.OnTheWay))
	if err != nil {
		return nil, err
	}
	return api.MarkOnTheWay200JSONResponse(b), nil
}

// MarkArrived implements POST /v1/provider/jobs/{bookingId}/arrived.
func (h *Handler) MarkArrived(ctx context.Context, req api.MarkArrivedRequestObject) (api.MarkArrivedResponseObject, error) {
	b, err := job(h.svc.Advance(ctx, me(ctx), req.BookingId, domain.Arrived))
	if err != nil {
		return nil, err
	}
	return api.MarkArrived200JSONResponse(b), nil
}

// StartJob implements POST /v1/provider/jobs/{bookingId}/start.
func (h *Handler) StartJob(ctx context.Context, req api.StartJobRequestObject) (api.StartJobResponseObject, error) {
	b, err := job(h.svc.Start(ctx, me(ctx), req.BookingId, req.Body.Code))
	if err != nil {
		return nil, err
	}
	return api.StartJob200JSONResponse(b), nil
}

// ProposeExtras implements POST /v1/provider/jobs/{bookingId}/extras.
func (h *Handler) ProposeExtras(ctx context.Context, req api.ProposeExtrasRequestObject) (api.ProposeExtrasResponseObject, error) {
	b, err := job(h.svc.ProposeExtras(ctx, me(ctx), req.BookingId, items(req.Body.Items)))
	if err != nil {
		return nil, err
	}
	return api.ProposeExtras200JSONResponse(b), nil
}

// CompleteJob implements POST /v1/provider/jobs/{bookingId}/complete.
func (h *Handler) CompleteJob(ctx context.Context, req api.CompleteJobRequestObject) (api.CompleteJobResponseObject, error) {
	b, err := job(h.svc.Complete(ctx, me(ctx), req.BookingId, req.Body.CashReceived))
	if err != nil {
		return nil, err
	}
	return api.CompleteJob200JSONResponse(b), nil
}

// CancelProviderJob implements POST /v1/provider/jobs/{bookingId}/cancel.
func (h *Handler) CancelProviderJob(ctx context.Context, req api.CancelProviderJobRequestObject) (api.CancelProviderJobResponseObject, error) {
	b, err := job(h.svc.Cancel(ctx, domain.ByProvider, me(ctx), req.BookingId, reason(string(req.Body.Reason), req.Body.Note)))
	if err != nil {
		return nil, err
	}
	return api.CancelProviderJob200JSONResponse(b), nil
}

// GetProviderReceipt implements GET /v1/provider/jobs/{bookingId}/receipt.
func (h *Handler) GetProviderReceipt(ctx context.Context, req api.GetProviderReceiptRequestObject) (api.GetProviderReceiptResponseObject, error) {
	b, err := h.svc.Receipt(ctx, me(ctx), req.BookingId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetProviderReceipt200JSONResponse(receipt(b)), nil
}
