// Package http serves the catalog operations: browsing and search for the apps, and
// catalog and price management for admins (A-02).
package http

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the catalog part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the catalog handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

var errorMap = httpx.ErrorMap{
	domain.ErrNotFound:      httpx.ErrNotFound,
	domain.ErrInvalid:       httpx.ErrValidation,
	domain.ErrPriceNegative: httpx.ErrValidation.WithDetails(map[string]any{"field": "amount"}),
}

// GetCatalog implements GET /v1/customer/catalog.
func (h *Handler) GetCatalog(ctx context.Context, _ api.GetCatalogRequestObject) (api.GetCatalogResponseObject, error) {
	t, err := h.svc.PublishedTree(ctx)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetCatalog200JSONResponse(tree(t)), nil
}

// GetProviderCatalog implements GET /v1/provider/catalog.
func (h *Handler) GetProviderCatalog(ctx context.Context, _ api.GetProviderCatalogRequestObject) (api.GetProviderCatalogResponseObject, error) {
	t, err := h.svc.PublishedTree(ctx)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetProviderCatalog200JSONResponse(tree(t)), nil
}

// GetAdminCatalog implements GET /v1/admin/catalog.
func (h *Handler) GetAdminCatalog(ctx context.Context, _ api.GetAdminCatalogRequestObject) (api.GetAdminCatalogResponseObject, error) {
	t, err := h.svc.AdminTree(ctx)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetAdminCatalog200JSONResponse(tree(t)), nil
}

// GetService implements GET /v1/customer/services/{serviceId}.
func (h *Handler) GetService(ctx context.Context, req api.GetServiceRequestObject) (api.GetServiceResponseObject, error) {
	s, err := h.svc.PublishedService(ctx, req.ServiceId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetService200JSONResponse(service(s)), nil
}

// SearchCatalog implements GET /v1/customer/catalog/search.
func (h *Handler) SearchCatalog(ctx context.Context, req api.SearchCatalogRequestObject) (api.SearchCatalogResponseObject, error) {
	services, subs, err := h.svc.Search(ctx, req.Params.Q)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	out := api.SearchCatalog200JSONResponse{Services: []api.Service{}, SubServices: []api.SubService{}}
	for _, s := range services {
		out.Services = append(out.Services, service(s))
	}
	for _, s := range subs {
		out.SubServices = append(out.SubServices, subService(s))
	}
	return out, nil
}

// actorFrom returns the signed-in admin.
func actorFrom(ctx context.Context) httpx.Principal {
	p, _ := httpx.PrincipalFrom(ctx)
	return p
}
