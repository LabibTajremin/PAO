package http

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// ListLevel2Sessions implements GET /v1/admin/level2-sessions.
func (h *Handler) ListLevel2Sessions(ctx context.Context, req api.ListLevel2SessionsRequestObject) (api.ListLevel2SessionsResponseObject, error) {
	limit, cur, err := page(req.Params.Cursor, req.Params.Limit)
	if err != nil {
		return nil, err
	}
	f, p := port.SessionFilter{ProviderID: req.Params.ProviderId}, port.Page{Limit: limit + 1}
	if req.Params.Status != nil {
		f.Status = string(*req.Params.Status)
	}
	if cur != nil {
		p.At, p.ID = &cur.CreatedAt, cur.ID
	}
	list, err := h.svc.Sessions(ctx, f, p)
	if err != nil {
		return nil, err
	}
	out := api.ListLevel2Sessions200JSONResponse{Items: []api.Level2Session{}}
	for i, s := range list {
		if i == limit {
			next := httpx.EncodeCursor(httpx.Cursor{CreatedAt: list[i-1].CreatedAt, ID: list[i-1].ID})
			out.NextCursor = &next
			break
		}
		out.Items = append(out.Items, session(s))
	}
	return out, nil
}

// ScheduleLevel2Session implements POST /v1/admin/level2-sessions.
func (h *Handler) ScheduleLevel2Session(ctx context.Context, req api.ScheduleLevel2SessionRequestObject) (api.ScheduleLevel2SessionResponseObject, error) {
	b := req.Body
	s, err := h.svc.Schedule(ctx, b.ProviderId, b.ServiceId, b.ScheduledAt, b.Location)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.ScheduleLevel2Session201JSONResponse(session(s)), nil
}

// GetLevel2Session implements GET /v1/admin/level2-sessions/{sessionId}.
func (h *Handler) GetLevel2Session(ctx context.Context, req api.GetLevel2SessionRequestObject) (api.GetLevel2SessionResponseObject, error) {
	s, err := h.svc.Session(ctx, req.SessionId)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetLevel2Session200JSONResponse(session(s)), nil
}

// RecordLevel2Result implements POST /v1/admin/level2-sessions/{sessionId}/result.
func (h *Handler) RecordLevel2Result(ctx context.Context, req api.RecordLevel2ResultRequestObject) (api.RecordLevel2ResultResponseObject, error) {
	b := req.Body
	o := domain.Outcome{Result: string(b.Result)}
	for _, c := range b.Checklist {
		o.Checklist = append(o.Checklist, domain.CheckItem(c))
	}
	if b.Notes != nil {
		o.Notes = *b.Notes
	}
	if b.VisitLocation != nil {
		o.VisitLat, o.VisitLng = &b.VisitLocation.Lat, &b.VisitLocation.Lng
	}
	if b.PhotoMediaIds != nil {
		o.Photos = *b.PhotoMediaIds
	}
	s, err := h.svc.RecordResult(ctx, req.SessionId, principal(ctx).AccountID, o)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.RecordLevel2Result200JSONResponse(session(s)), nil
}
