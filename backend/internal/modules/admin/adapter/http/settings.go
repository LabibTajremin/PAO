// Package http serves the admin endpoints owned by the admin module.
package http

import (
	"context"
	"net/http"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the admin part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the admin handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

var errorMap = httpx.ErrorMap{
	domain.ErrNotFound: httpx.ErrNotFound,
	domain.ErrInvalid:  httpx.NewError(http.StatusUnprocessableEntity, "SETTING_INVALID", "This value does not fit the setting."),
}

func toSetting(s domain.Setting) api.Setting {
	out := api.Setting{Key: s.Key, Value: s.Value, Type: api.SettingType(s.Type), Description: s.Description, UpdatedBy: s.UpdatedBy}
	if !s.UpdatedAt.IsZero() {
		out.UpdatedAt = &s.UpdatedAt
	}
	return out
}

// ListSettings implements GET /v1/admin/settings.
func (h *Handler) ListSettings(ctx context.Context, _ api.ListSettingsRequestObject) (api.ListSettingsResponseObject, error) {
	list, err := h.svc.Settings(ctx)
	if err != nil {
		return nil, err
	}
	items := make([]api.Setting, 0, len(list))
	for _, s := range list {
		items = append(items, toSetting(s))
	}
	return api.ListSettings200JSONResponse{Items: items}, nil
}

// UpdateSetting implements PUT /v1/admin/settings/{key}.
func (h *Handler) UpdateSetting(ctx context.Context, req api.UpdateSettingRequestObject) (api.UpdateSettingResponseObject, error) {
	p, _ := httpx.PrincipalFrom(ctx)
	s, err := h.svc.UpdateSetting(ctx, p.AccountID, req.Key, req.Body.Value)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.UpdateSetting200JSONResponse(toSetting(s)), nil
}
