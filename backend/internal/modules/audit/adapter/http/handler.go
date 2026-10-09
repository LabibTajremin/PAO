// Package http serves the audit log viewer (A-08).
package http

import (
	"context"
	"time"

	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the audit part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the audit handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

// ListAuditEntries implements GET /v1/admin/audit.
func (h *Handler) ListAuditEntries(ctx context.Context, req api.ListAuditEntriesRequestObject) (api.ListAuditEntriesResponseObject, error) {
	cur, err := httpx.DecodeCursor(req.Params.Cursor)
	if err != nil {
		return nil, err
	}
	limit := httpx.PageSize(req.Params.Limit)
	f := domain.Filter{ActorID: req.Params.ActorId, Action: deref(req.Params.Action), SubjectID: deref(req.Params.SubjectId), From: req.Params.From, To: req.Params.To}
	page := port.Page{Limit: limit + 1}
	if cur != nil {
		page.At, page.ID = &cur.CreatedAt, cur.ID
	}
	entries, err := h.svc.List(ctx, f, page)
	if err != nil {
		return nil, err
	}
	out := api.ListAuditEntries200JSONResponse{Items: []api.AuditEntry{}}
	for i, e := range entries {
		if i == limit {
			next := httpx.EncodeCursor(httpx.Cursor{CreatedAt: entries[i-1].At, ID: entries[i-1].ID})
			out.NextCursor = &next
			break
		}
		out.Items = append(out.Items, Entry(e))
	}
	return out, nil
}

// Entry maps a domain entry to the API shape; other admin screens reuse it.
func Entry(e domain.Entry) api.AuditEntry {
	out := api.AuditEntry{Id: e.ID, At: e.At.In(time.UTC), ActorId: e.ActorID, Action: e.Action, SubjectType: e.SubjectType, SubjectId: e.SubjectID}
	if e.ActorRole != "" {
		out.ActorRole = &e.ActorRole
	}
	if e.Reason != "" {
		out.Reason = &e.Reason
	}
	if e.Before != nil {
		out.Before = &e.Before
	}
	if e.After != nil {
		out.After = &e.After
	}
	return out
}

func deref(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
