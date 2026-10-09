package http

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/catalog/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// CreateCategory implements POST /v1/admin/catalog/categories.
func (h *Handler) CreateCategory(ctx context.Context, req api.CreateCategoryRequestObject) (api.CreateCategoryResponseObject, error) {
	c, err := h.svc.SaveCategory(ctx, categoryInput(uuid.Nil, *req.Body))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.CreateCategory201JSONResponse(category(c)), nil
}

// UpdateCategory implements PUT /v1/admin/catalog/categories/{categoryId}.
func (h *Handler) UpdateCategory(ctx context.Context, req api.UpdateCategoryRequestObject) (api.UpdateCategoryResponseObject, error) {
	c, err := h.svc.SaveCategory(ctx, categoryInput(req.CategoryId, *req.Body))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.UpdateCategory200JSONResponse(category(c)), nil
}

// CreateService implements POST /v1/admin/catalog/services.
func (h *Handler) CreateService(ctx context.Context, req api.CreateServiceRequestObject) (api.CreateServiceResponseObject, error) {
	s, err := h.svc.SaveService(ctx, serviceInput(uuid.Nil, *req.Body))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.CreateService201JSONResponse(service(s)), nil
}

// UpdateService implements PUT /v1/admin/catalog/services/{serviceId}.
func (h *Handler) UpdateService(ctx context.Context, req api.UpdateServiceRequestObject) (api.UpdateServiceResponseObject, error) {
	s, err := h.svc.SaveService(ctx, serviceInput(req.ServiceId, *req.Body))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.UpdateService200JSONResponse(service(s)), nil
}

// CreateSubService implements POST /v1/admin/catalog/sub-services; initialPrice is required.
func (h *Handler) CreateSubService(ctx context.Context, req api.CreateSubServiceRequestObject) (api.CreateSubServiceResponseObject, error) {
	if req.Body.InitialPrice == nil {
		return nil, errorMap.Map(domain.ErrPriceNegative)
	}
	s, err := h.svc.CreateSubService(ctx, subServiceInput(uuid.Nil, *req.Body), *req.Body.InitialPrice, actorFrom(ctx).AccountID)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.CreateSubService201JSONResponse(subService(s)), nil
}

// UpdateSubService implements PUT /v1/admin/catalog/sub-services/{subServiceId}.
func (h *Handler) UpdateSubService(ctx context.Context, req api.UpdateSubServiceRequestObject) (api.UpdateSubServiceResponseObject, error) {
	s, err := h.svc.UpdateSubService(ctx, subServiceInput(req.SubServiceId, *req.Body))
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.UpdateSubService200JSONResponse(subService(s)), nil
}

// ChangePrice implements POST /v1/admin/catalog/sub-services/{subServiceId}/prices.
func (h *Handler) ChangePrice(ctx context.Context, req api.ChangePriceRequestObject) (api.ChangePriceResponseObject, error) {
	p, err := h.svc.ChangePrice(ctx, req.SubServiceId, req.Body.Amount, actorFrom(ctx).AccountID)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.ChangePrice201JSONResponse(price(p)), nil
}

// ListPriceHistory implements GET /v1/admin/catalog/sub-services/{subServiceId}/prices.
func (h *Handler) ListPriceHistory(ctx context.Context, req api.ListPriceHistoryRequestObject) (api.ListPriceHistoryResponseObject, error) {
	hist, err := h.svc.PriceHistory(ctx, req.SubServiceId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	out := api.ListPriceHistory200JSONResponse{Items: []api.PriceVersion{}}
	for _, p := range hist {
		out.Items = append(out.Items, price(p))
	}
	return out, nil
}
