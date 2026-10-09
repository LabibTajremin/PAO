package http

import (
	"context"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// GetDashboard implements GET /v1/admin/dashboard.
func (h *Handler) GetDashboard(ctx context.Context, _ api.GetDashboardRequestObject) (api.GetDashboardResponseObject, error) {
	d, err := h.svc.Dashboard(ctx)
	if err != nil {
		return nil, err
	}
	out := api.GetDashboard200JSONResponse{ProvidersByStatus: d.ProvidersByStatus, ProvidersByLevel: d.ProvidersByLevel,
		CompletionRate: d.CompletionRate, OpenComplaints: d.OpenComplaints, PendingVerifications: d.PendingVerifications, GeneratedAt: d.GeneratedAt}
	for _, day := range d.BookingsPerDay {
		out.BookingsPerDay = append(out.BookingsPerDay, struct {
			Completed int                `json:"completed"`
			Date      openapi_types.Date `json:"date"`
			Total     int                `json:"total"`
		}{Completed: day.Completed, Date: openapi_types.Date{Time: day.Date}, Total: day.Total})
	}
	return out, nil
}
