package http

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

func me(ctx context.Context) uuid.UUID {
	p, _ := httpx.PrincipalFrom(ctx)
	return p.AccountID
}

func toComplaint(c domain.Complaint) api.Complaint {
	photos, comments := c.Photos, make([]api.ComplaintComment, 0, len(c.Comments))
	for _, cm := range c.Comments {
		comments = append(comments, api.ComplaintComment{AuthorId: cm.AuthorID, Body: cm.Body, At: cm.At})
	}
	return api.Complaint{Id: c.ID, TicketNumber: c.TicketNumber(), BookingId: c.BookingID, ReporterRole: api.ComplaintReporterRole(c.ReporterRole),
		ReporterId: c.ReporterID, AgainstId: &c.AgainstID, Reason: api.ComplaintReason(c.Reason), Description: c.Description,
		PhotoMediaIds: &photos, Status: api.ComplaintStatus(c.Status), AssigneeId: c.AssigneeID, Resolution: &c.Resolution,
		Verified: &c.Verified, Comments: &comments, CreatedAt: c.CreatedAt, ResolvedAt: c.ResolvedAt}
}

func (h *Handler) report(ctx context.Context, role string, booking uuid.UUID, in *api.ComplaintInput) (api.Complaint, error) {
	c := domain.Complaint{BookingID: booking, ReporterID: me(ctx), ReporterRole: role, Reason: string(in.Reason), Description: in.Description,
		Photos: []uuid.UUID{}}
	if in.PhotoMediaIds != nil {
		c.Photos = *in.PhotoMediaIds
	}
	c, err := h.svc.Report(ctx, c)
	return toComplaint(c), errorMap.Map(err)
}

// ReportCustomerProblem implements POST /v1/customer/bookings/{bookingId}/reports.
func (h *Handler) ReportCustomerProblem(ctx context.Context, req api.ReportCustomerProblemRequestObject) (api.ReportCustomerProblemResponseObject, error) {
	c, err := h.report(ctx, "customer", req.BookingId, req.Body)
	if err != nil {
		return nil, err
	}
	return api.ReportCustomerProblem201JSONResponse(c), nil
}

// ReportProviderProblem implements POST /v1/provider/jobs/{bookingId}/reports.
func (h *Handler) ReportProviderProblem(ctx context.Context, req api.ReportProviderProblemRequestObject) (api.ReportProviderProblemResponseObject, error) {
	c, err := h.report(ctx, "provider", req.BookingId, req.Body)
	if err != nil {
		return nil, err
	}
	return api.ReportProviderProblem201JSONResponse(c), nil
}

// ListComplaints implements GET /v1/admin/complaints.
func (h *Handler) ListComplaints(ctx context.Context, req api.ListComplaintsRequestObject) (api.ListComplaintsResponseObject, error) {
	cur, err := httpx.DecodeCursor(req.Params.Cursor)
	if err != nil {
		return nil, err
	}
	size := httpx.PageSize(req.Params.Limit)
	f := port.ComplaintFilter{Status: (*string)(req.Params.Status), AssigneeID: req.Params.AssigneeId, Limit: size + 1}
	if cur != nil {
		f.At, f.ID = &cur.CreatedAt, cur.ID
	}
	list, err := h.svc.Complaints(ctx, f)
	if err != nil {
		return nil, err
	}
	out := api.ListComplaints200JSONResponse{Items: []api.Complaint{}}
	for i, c := range list {
		if i == size {
			next := httpx.EncodeCursor(httpx.Cursor{CreatedAt: list[i-1].CreatedAt, ID: list[i-1].ID})
			out.NextCursor = &next
			break
		}
		out.Items = append(out.Items, toComplaint(c))
	}
	return out, nil
}

// GetComplaint implements GET /v1/admin/complaints/{complaintId}.
func (h *Handler) GetComplaint(ctx context.Context, req api.GetComplaintRequestObject) (api.GetComplaintResponseObject, error) {
	c, err := h.svc.Complaint(ctx, req.ComplaintId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetComplaint200JSONResponse(toComplaint(c)), nil
}

// AssignComplaint implements POST /v1/admin/complaints/{complaintId}/assign.
func (h *Handler) AssignComplaint(ctx context.Context, req api.AssignComplaintRequestObject) (api.AssignComplaintResponseObject, error) {
	c, err := h.svc.Assign(ctx, req.ComplaintId, req.Body.AssigneeId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.AssignComplaint200JSONResponse(toComplaint(c)), nil
}

// CommentOnComplaint implements POST /v1/admin/complaints/{complaintId}/comments.
func (h *Handler) CommentOnComplaint(ctx context.Context, req api.CommentOnComplaintRequestObject) (api.CommentOnComplaintResponseObject, error) {
	c, err := h.svc.Comment(ctx, req.ComplaintId, me(ctx), req.Body.Body)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.CommentOnComplaint201JSONResponse(toComplaint(c)), nil
}

// ResolveComplaint implements POST /v1/admin/complaints/{complaintId}/resolve.
func (h *Handler) ResolveComplaint(ctx context.Context, req api.ResolveComplaintRequestObject) (api.ResolveComplaintResponseObject, error) {
	c, err := h.svc.Resolve(ctx, req.ComplaintId, me(ctx), req.Body.Resolution, req.Body.Verified)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.ResolveComplaint200JSONResponse(toComplaint(c)), nil
}
