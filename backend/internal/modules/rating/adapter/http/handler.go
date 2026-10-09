// Package http serves reviews and rating breakdowns.
package http

import (
	"context"
	"net/http"
	"strconv"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/rating/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the rating part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the rating handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

var errorMap = httpx.ErrorMap{
	domain.ErrNotAllowed:      httpx.NewError(http.StatusConflict, "REVIEW_NOT_ALLOWED", "You can review only your own completed bookings."),
	domain.ErrAlreadyReviewed: httpx.NewError(http.StatusConflict, "REVIEW_ALREADY_SUBMITTED", "You already reviewed this booking."),
	domain.ErrInvalid:         httpx.NewError(http.StatusUnprocessableEntity, "VALIDATION_FAILED", "Check the review and try again."),
}

func me(ctx context.Context) uuid.UUID {
	p, _ := httpx.PrincipalFrom(ctx)
	return p.AccountID
}

func review(r domain.Review) api.Review {
	out := api.Review{Id: r.ID, BookingId: r.BookingID, Stars: r.Stars, AuthorName: r.AuthorName, CreatedAt: r.CreatedAt.UTC(),
		ServiceName: &api.LocalizedText{En: r.ServiceName.EN, Bn: r.ServiceName.BN}, Tags: []api.ReviewTag{}}
	for _, t := range r.Tags {
		out.Tags = append(out.Tags, api.ReviewTag(t))
	}
	if r.Comment != "" {
		out.Comment = &r.Comment
	}
	return out
}

func (h *Handler) review(ctx context.Context, role string, booking uuid.UUID, in api.ReviewInput) (api.Review, error) {
	var tags []string
	if in.Tags != nil {
		for _, t := range *in.Tags {
			tags = append(tags, string(t))
		}
	}
	comment := ""
	if in.Comment != nil {
		comment = *in.Comment
	}
	r, err := h.svc.Review(ctx, me(ctx), role, booking, in.Stars, tags, comment)
	if err != nil {
		return api.Review{}, errorMap.Map(err)
	}
	return review(r), nil
}

// ReviewProvider implements POST /v1/customer/bookings/{bookingId}/review.
func (h *Handler) ReviewProvider(ctx context.Context, req api.ReviewProviderRequestObject) (api.ReviewProviderResponseObject, error) {
	r, err := h.review(ctx, domain.Customer, req.BookingId, *req.Body)
	if err != nil {
		return nil, err
	}
	return api.ReviewProvider201JSONResponse(r), nil
}

// ReviewCustomer implements POST /v1/provider/jobs/{bookingId}/review.
func (h *Handler) ReviewCustomer(ctx context.Context, req api.ReviewCustomerRequestObject) (api.ReviewCustomerResponseObject, error) {
	r, err := h.review(ctx, domain.Provider, req.BookingId, *req.Body)
	if err != nil {
		return nil, err
	}
	return api.ReviewCustomer201JSONResponse(r), nil
}

// Breakdown maps an aggregate; the provider profile reuses it.
func Breakdown(a domain.Aggregate) api.RatingBreakdown {
	dist := map[string]int{}
	for i, n := range a.Distribution {
		dist[strconv.Itoa(i+1)] = n
	}
	return api.RatingBreakdown{Average: a.Average(), Count: a.Count, Distribution: dist}
}

// GetMyRating implements GET /v1/provider/rating.
func (h *Handler) GetMyRating(ctx context.Context, _ api.GetMyRatingRequestObject) (api.GetMyRatingResponseObject, error) {
	a, err := h.svc.Summary(ctx, domain.Provider, me(ctx))
	if err != nil {
		return nil, err
	}
	return api.GetMyRating200JSONResponse(Breakdown(a)), nil
}

func (h *Handler) reviews(ctx context.Context, provider uuid.UUID, cursor *string, limit *int) (api.ReviewList, error) {
	cur, err := httpx.DecodeCursor(cursor)
	if err != nil {
		return api.ReviewList{}, err
	}
	size := httpx.PageSize(limit)
	p := port.Page{Limit: size + 1}
	if cur != nil {
		p.At, p.ID = &cur.CreatedAt, cur.ID
	}
	rows, err := h.svc.ProviderReviews(ctx, provider, p)
	if err != nil {
		return api.ReviewList{}, err
	}
	out := api.ReviewList{Items: []api.Review{}}
	for i, r := range rows {
		if i == size {
			next := httpx.EncodeCursor(httpx.Cursor{CreatedAt: rows[i-1].CreatedAt, ID: rows[i-1].ID})
			out.NextCursor = &next
			break
		}
		out.Items = append(out.Items, review(r))
	}
	return out, nil
}

// ListMyReviews implements GET /v1/provider/reviews.
func (h *Handler) ListMyReviews(ctx context.Context, req api.ListMyReviewsRequestObject) (api.ListMyReviewsResponseObject, error) {
	out, err := h.reviews(ctx, me(ctx), req.Params.Cursor, req.Params.Limit)
	if err != nil {
		return nil, err
	}
	return api.ListMyReviews200JSONResponse(out), nil
}

// ListProviderReviews implements GET /v1/customer/providers/{providerId}/reviews.
func (h *Handler) ListProviderReviews(ctx context.Context, req api.ListProviderReviewsRequestObject) (api.ListProviderReviewsResponseObject, error) {
	out, err := h.reviews(ctx, req.ProviderId, req.Params.Cursor, req.Params.Limit)
	if err != nil {
		return nil, err
	}
	return api.ListProviderReviews200JSONResponse(out), nil
}
