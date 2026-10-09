package http

import (
	"context"
	"time"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

func date(d *openapi_types.Date) *time.Time {
	if d == nil {
		return nil
	}
	return &d.Time
}

// GetEarningsSummary implements GET /v1/provider/earnings/summary.
func (h *Handler) GetEarningsSummary(ctx context.Context, req api.GetEarningsSummaryRequestObject) (api.GetEarningsSummaryResponseObject, error) {
	e, err := h.svc.Earnings(ctx, me(ctx), string(req.Params.Period), date(req.Params.Date))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	out := api.GetEarningsSummary200JSONResponse{Period: api.EarningsPeriod(req.Params.Period), From: openapi_types.Date{Time: e.From},
		To: openapi_types.Date{Time: e.To}, Total: e.Total, Jobs: e.Jobs}
	for _, d := range e.Days {
		out.Buckets = append(out.Buckets, struct {
			Date  openapi_types.Date `json:"date"`
			Jobs  int                `json:"jobs"`
			Total api.Money          `json:"total"`
		}{Date: openapi_types.Date{Time: d.Day}, Jobs: d.Jobs, Total: d.Total})
	}
	return out, nil
}

// ListEarningsJobs implements GET /v1/provider/earnings/jobs.
func (h *Handler) ListEarningsJobs(ctx context.Context, req api.ListEarningsJobsRequestObject) (api.ListEarningsJobsResponseObject, error) {
	cur, err := httpx.DecodeCursor(req.Params.Cursor)
	if err != nil {
		return nil, err
	}
	size := httpx.PageSize(req.Params.Limit)
	p := port.Page{Limit: size + 1}
	if cur != nil {
		p.At, p.ID = &cur.CreatedAt, cur.ID
	}
	rows, err := h.svc.EarningsJobs(ctx, me(ctx), date(req.Params.From), date(req.Params.To), p)
	if err != nil {
		return nil, err
	}
	out := api.ListEarningsJobs200JSONResponse{Items: []api.EarningsJob{}}
	for i, r := range rows {
		if i == size {
			next := httpx.EncodeCursor(httpx.Cursor{CreatedAt: rows[i-1].CompletedAt, ID: rows[i-1].ID})
			out.NextCursor = &next
			break
		}
		out.Items = append(out.Items, api.EarningsJob{BookingId: r.ID, Number: app.Number(r.Number), CompletedAt: r.CompletedAt.UTC(),
			ServiceName: text(r.ServiceName), Total: r.TotalPaisa})
	}
	return out, nil
}

// FindNearbyProviders implements GET /v1/customer/providers/nearby.
func (h *Handler) FindNearbyProviders(ctx context.Context, req api.FindNearbyProvidersRequestObject) (api.FindNearbyProvidersResponseObject, error) {
	q := req.Params
	in := app.NearbyQuery{CustomerID: me(ctx), ServiceID: q.ServiceId, SubServiceID: q.SubServiceId, Quantity: q.Quantity,
		AddressID: q.AddressId, ByRating: q.Sort != nil && *q.Sort == "rating", Limit: httpx.PageSize(q.Limit)}
	if q.Lat != nil && q.Lng != nil {
		in.At = &domain.Point{Lat: *q.Lat, Lng: *q.Lng}
	}
	res, err := h.svc.Nearby(ctx, in)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	out := api.FindNearbyProviders200JSONResponse{Items: []api.ProviderCard{}, PriceSummary: api.PriceSummary{SubServiceId: res.Price.SubServiceID,
		Quantity: res.Price.Quantity, UnitPrice: res.Price.UnitPaisa, Total: res.Price.TotalPaisa}}
	for _, c := range res.Providers {
		card := api.ProviderCard{Id: c.ID, Name: c.Name, Badge: badge(c.Level), Level: c.Level, Rating: c.Rating, RatingCount: c.RatingCount,
			CompletedJobs: c.CompletedJobs, DistanceM: c.DistanceM}
		if c.PhotoURL != "" {
			card.PhotoUrl = &c.PhotoURL
		}
		out.Items = append(out.Items, card)
	}
	return out, nil
}

// badge maps a search result's level; search only returns verified providers.
func badge(level int) api.Badge {
	if level >= 2 {
		return api.VerifiedPro
	}
	return api.Verified
}
