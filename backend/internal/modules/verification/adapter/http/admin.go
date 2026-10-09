package http

import (
	"context"
	"strconv"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// ListVerificationQueue implements GET /v1/admin/verifications.
func (h *Handler) ListVerificationQueue(ctx context.Context, req api.ListVerificationQueueRequestObject) (api.ListVerificationQueueResponseObject, error) {
	limit, cur, err := page(req.Params.Cursor, req.Params.Limit)
	if err != nil {
		return nil, err
	}
	f, p := port.QueueFilter{ServiceID: req.Params.ServiceId}, port.Page{Limit: limit + 1}
	if req.Params.ItemType != nil {
		f.ItemType = string(*req.Params.ItemType)
	}
	if cur != nil {
		p.At, p.ID = &cur.CreatedAt, cur.ID
	}
	rows, err := h.svc.Queue(ctx, f, p)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	out := api.ListVerificationQueue200JSONResponse{Items: []api.VerificationQueueItem{}}
	for i, r := range rows {
		if i == limit {
			next := httpx.EncodeCursor(httpx.Cursor{CreatedAt: rows[i-1].SubmittedAt, ID: rows[i-1].ProviderID})
			out.NextCursor = &next
			break
		}
		out.Items = append(out.Items, queueItem(r))
	}
	return out, nil
}

func queueItem(r app.QueueEntry) api.VerificationQueueItem {
	out := api.VerificationQueueItem{ProviderId: r.ProviderID, Name: r.Name, SubmittedAt: r.SubmittedAt.UTC(), AgeHours: r.AgeHours}
	for _, t := range r.PendingItems {
		out.PendingItems = append(out.PendingItems, api.ItemType(t))
	}
	services := []api.ServiceRef{}
	for _, s := range r.Services {
		services = append(services, api.ServiceRef{Id: s.ID, Name: api.LocalizedText{En: s.Name.EN, Bn: s.Name.BN}})
	}
	out.Services = &services
	return out
}

// profileFields shows the profile data a verifier checks for each profile item.
func profileFields(r app.Review) map[string]map[string]string {
	p := r.Provider
	out := map[string]map[string]string{
		"address":      {"presentAddress": p.PresentAddress, "permanentAddress": p.PermanentAddress},
		"service_area": {"workingRadiusM": strconv.Itoa(p.WorkingRadiusM), "services": strconv.Itoa(len(p.ServiceIDs))},
	}
	if p.HomeBase != nil {
		out["service_area"]["homeLat"] = strconv.FormatFloat(p.HomeBase.Lat, 'f', 6, 64)
		out["service_area"]["homeLng"] = strconv.FormatFloat(p.HomeBase.Lng, 'f', 6, 64)
	}
	if c := p.EmergencyContact; c != nil {
		out["emergency_contact"] = map[string]string{"name": c.Name, "relation": c.Relation, "phone": c.Phone}
	}
	return out
}

func review(r app.Review) api.VerificationReview {
	p := r.Provider
	out := api.VerificationReview{ProviderId: p.ID, Level: r.Level}
	out.Profile.FullName, out.Profile.Gender, out.Profile.Phone = p.FullName, api.Gender(p.Gender), p.Phone
	out.Profile.PresentAddress, out.Profile.PermanentAddress = &p.PresentAddress, &p.PermanentAddress
	if p.DateOfBirth != nil {
		out.Profile.DateOfBirth = openapi_types.Date{Time: *p.DateOfBirth}
	}
	if r.NIDNumber != "" {
		out.Profile.NidNumber = &r.NIDNumber
	}
	face := api.NotRun
	if r.Item("selfie").Status != domain.Missing {
		face = api.ManualReview
	}
	out.FaceMatch = &face
	extra := profileFields(r)
	for _, t := range domain.Types {
		it := r.Item(t)
		base := item(it)
		fields := map[string]string{}
		for k, v := range it.Fields {
			fields[k] = v
		}
		for k, v := range extra[t] {
			fields[k] = v
		}
		docs := []api.ReviewDocument{}
		for _, d := range r.Documents {
			if d.ItemType == t {
				docs = append(docs, api.ReviewDocument{MediaId: d.MediaID, Kind: d.Kind})
			}
		}
		out.Items = append(out.Items, api.ReviewItem{Type: base.Type, Status: base.Status, Required: base.Required, RejectionReason: base.RejectionReason,
			DecidedAt: base.DecidedAt, ExpiresAt: base.ExpiresAt, Fields: &fields, Documents: &docs})
	}
	return out
}

// GetVerificationReview implements GET /v1/admin/verifications/{providerId}.
func (h *Handler) GetVerificationReview(ctx context.Context, req api.GetVerificationReviewRequestObject) (api.GetVerificationReviewResponseObject, error) {
	r, err := h.svc.Review(ctx, req.ProviderId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetVerificationReview200JSONResponse(review(r)), nil
}

// ApproveVerificationItem implements POST /v1/admin/verifications/{providerId}/items/{itemType}/approve.
func (h *Handler) ApproveVerificationItem(ctx context.Context, req api.ApproveVerificationItemRequestObject) (api.ApproveVerificationItemResponseObject, error) {
	r, err := h.svc.Decide(ctx, req.ProviderId, string(req.ItemType), principal(ctx).AccountID, true, "")
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.ApproveVerificationItem200JSONResponse(review(r)), nil
}

// RejectVerificationItem implements POST /v1/admin/verifications/{providerId}/items/{itemType}/reject.
func (h *Handler) RejectVerificationItem(ctx context.Context, req api.RejectVerificationItemRequestObject) (api.RejectVerificationItemResponseObject, error) {
	r, err := h.svc.Decide(ctx, req.ProviderId, string(req.ItemType), principal(ctx).AccountID, false, req.Body.Reason)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.RejectVerificationItem200JSONResponse(review(r)), nil
}
