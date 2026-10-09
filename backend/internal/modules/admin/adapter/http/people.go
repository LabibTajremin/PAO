package http

import (
	"context"

	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// ListAdminProviders implements GET /v1/admin/providers.
func (h *Handler) ListAdminProviders(ctx context.Context, req api.ListAdminProvidersRequestObject) (api.ListAdminProvidersResponseObject, error) {
	p := req.Params
	cur, size, err := page(p.Cursor, p.Limit)
	if err != nil {
		return nil, err
	}
	q := provider.ProviderQuery{Level: p.Level, Flagged: p.Flagged, Limit: size + 1}
	if p.Q != nil {
		q.Text = *p.Q
	}
	if p.Status != nil {
		q.Status = string(*p.Status)
	}
	if cur != nil {
		q.AfterAt, q.AfterID = &cur.CreatedAt, cur.ID
	}
	list, err := h.svc.Providers(ctx, q)
	if err != nil {
		return nil, err
	}
	out := api.ListAdminProviders200JSONResponse{Items: []api.AdminProviderSummary{}}
	for i, r := range list {
		if i == size {
			next := httpx.EncodeCursor(httpx.Cursor{CreatedAt: list[i-1].CreatedAt, ID: list[i-1].ID})
			out.NextCursor = &next
			break
		}
		out.Items = append(out.Items, providerSummary(r, h.svc.Services(ctx, r.ServiceIDs)))
	}
	return out, nil
}

// GetAdminProvider implements GET /v1/admin/providers/{providerId}.
func (h *Handler) GetAdminProvider(ctx context.Context, req api.GetAdminProviderRequestObject) (api.GetAdminProviderResponseObject, error) {
	d, err := h.svc.ProviderDetail(ctx, req.ProviderId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetAdminProvider200JSONResponse(providerDetail(d)), nil
}

// ChangeProviderStatus implements POST /v1/admin/providers/{providerId}/status.
func (h *Handler) ChangeProviderStatus(ctx context.Context, req api.ChangeProviderStatusRequestObject) (api.ChangeProviderStatusResponseObject, error) {
	d, err := h.svc.SetProviderStatus(ctx, me(ctx), req.ProviderId, string(req.Body.Status), req.Body.Reason)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.ChangeProviderStatus200JSONResponse(providerDetail(d)), nil
}
