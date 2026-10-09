package http

import (
	"context"

	customer "github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// ListAdminCustomers implements GET /v1/admin/customers.
func (h *Handler) ListAdminCustomers(ctx context.Context, req api.ListAdminCustomersRequestObject) (api.ListAdminCustomersResponseObject, error) {
	p := req.Params
	cur, size, err := page(p.Cursor, p.Limit)
	if err != nil {
		return nil, err
	}
	q := customer.CustomerQuery{Limit: size + 1}
	if p.Q != nil {
		q.Text = *p.Q
	}
	if p.Status != nil {
		q.Status = string(*p.Status)
	}
	if cur != nil {
		q.AfterAt, q.AfterID = &cur.CreatedAt, cur.ID
	}
	list, err := h.svc.Customers(ctx, q)
	if err != nil {
		return nil, err
	}
	out := api.ListAdminCustomers200JSONResponse{Items: []api.AdminCustomerSummary{}}
	for i, r := range list {
		if i == size {
			next := httpx.EncodeCursor(httpx.Cursor{CreatedAt: list[i-1].CreatedAt, ID: list[i-1].ID})
			out.NextCursor = &next
			break
		}
		out.Items = append(out.Items, customerSummary(r))
	}
	return out, nil
}

// GetAdminCustomer implements GET /v1/admin/customers/{customerId}.
func (h *Handler) GetAdminCustomer(ctx context.Context, req api.GetAdminCustomerRequestObject) (api.GetAdminCustomerResponseObject, error) {
	d, err := h.svc.CustomerDetail(ctx, req.CustomerId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetAdminCustomer200JSONResponse(customerDetail(d)), nil
}

// ChangeCustomerStatus implements POST /v1/admin/customers/{customerId}/status.
func (h *Handler) ChangeCustomerStatus(ctx context.Context, req api.ChangeCustomerStatusRequestObject) (api.ChangeCustomerStatusResponseObject, error) {
	d, err := h.svc.SetCustomerStatus(ctx, me(ctx), req.CustomerId, string(req.Body.Status), req.Body.Reason)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.ChangeCustomerStatus200JSONResponse(customerDetail(d)), nil
}
