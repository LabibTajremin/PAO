package http

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// GetMe implements GET /v1/me.
func (h *Handler) GetMe(ctx context.Context, _ api.GetMeRequestObject) (api.GetMeResponseObject, error) {
	p, _ := httpx.PrincipalFrom(ctx)
	a, err := h.svc.GetAccount(ctx, p.AccountID)
	if err != nil {
		return nil, mapError(err)
	}
	return api.GetMe200JSONResponse(account(a)), nil
}

// GetMyPermissions implements GET /v1/me/permissions.
func (h *Handler) GetMyPermissions(ctx context.Context, _ api.GetMyPermissionsRequestObject) (api.GetMyPermissionsResponseObject, error) {
	p, _ := httpx.PrincipalFrom(ctx)
	v, err := h.svc.Permissions(ctx, p.AccountID)
	if err != nil {
		return nil, mapError(err)
	}
	return api.GetMyPermissions200JSONResponse{
		Roles: roles(v.Roles), Permissions: orEmpty(v.Permissions), Screens: orEmpty(v.Screens), ProviderGate: &v.ProviderGate,
	}, nil
}

// DeleteMe implements DELETE /v1/me.
func (h *Handler) DeleteMe(ctx context.Context, req api.DeleteMeRequestObject) (api.DeleteMeResponseObject, error) {
	p, _ := httpx.PrincipalFrom(ctx)
	if err := h.svc.DeleteAccount(ctx, caller(p), req.Body.Code); err != nil {
		return nil, mapError(err)
	}
	return api.DeleteMe204Response{}, nil
}
