// Package http serves the upload endpoints of both apps and the admin document viewer.
package http

import (
	"context"
	"net/http"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/media/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx"
	"github.com/LabibTajremin/PAO/backend/internal/platform/httpx/api"
)

// Handler implements the media part of api.StrictServerInterface.
type Handler struct{ svc *app.Service }

// NewHandler returns the media handler.
func NewHandler(svc *app.Service) *Handler { return &Handler{svc: svc} }

var errorMap = httpx.ErrorMap{
	domain.ErrInvalid:     httpx.NewError(http.StatusUnprocessableEntity, "UPLOAD_INVALID", "This file type or size is not allowed here."),
	domain.ErrForbidden:   httpx.NewError(http.StatusUnprocessableEntity, "UPLOAD_INVALID", "This app cannot upload that kind of file."),
	domain.ErrNotFound:    httpx.ErrNotFound,
	domain.ErrNotUploaded: httpx.NewError(http.StatusConflict, "UPLOAD_NOT_FOUND", "The file did not arrive or does not match. Upload it again."),
}

func (h *Handler) create(ctx context.Context, uploader string, in api.UploadRequest) (api.UploadTicket, error) {
	p, _ := httpx.PrincipalFrom(ctx)
	t, err := h.svc.CreateUpload(ctx, p.AccountID, uploader, string(in.Purpose), string(in.ContentType), in.SizeBytes)
	if err != nil {
		return api.UploadTicket{}, errorMap.Map(err)
	}
	return api.UploadTicket{MediaId: t.MediaID, UploadUrl: t.URL, Headers: t.Headers, ExpiresAt: t.ExpiresAt}, nil
}

func (h *Handler) confirm(ctx context.Context, id uuid.UUID) (api.MediaObject, error) {
	p, _ := httpx.PrincipalFrom(ctx)
	o, err := h.svc.Confirm(ctx, p.AccountID, id)
	if err != nil {
		return api.MediaObject{}, errorMap.Map(err)
	}
	return api.MediaObject{Id: o.ID, Purpose: api.UploadPurpose(o.Purpose), ContentType: o.ContentType, SizeBytes: o.SizeBytes,
		Status: api.MediaObjectStatusConfirmed}, nil
}

// CreateCustomerUpload implements POST /v1/customer/uploads.
func (h *Handler) CreateCustomerUpload(ctx context.Context, req api.CreateCustomerUploadRequestObject) (api.CreateCustomerUploadResponseObject, error) {
	t, err := h.create(ctx, "customer", *req.Body)
	if err != nil {
		return nil, err
	}
	return api.CreateCustomerUpload201JSONResponse(t), nil
}

// ConfirmCustomerUpload implements POST /v1/customer/uploads/{mediaId}/confirm.
func (h *Handler) ConfirmCustomerUpload(ctx context.Context, req api.ConfirmCustomerUploadRequestObject) (api.ConfirmCustomerUploadResponseObject, error) {
	o, err := h.confirm(ctx, req.MediaId)
	if err != nil {
		return nil, err
	}
	return api.ConfirmCustomerUpload200JSONResponse(o), nil
}

// CreateProviderUpload implements POST /v1/provider/uploads.
func (h *Handler) CreateProviderUpload(ctx context.Context, req api.CreateProviderUploadRequestObject) (api.CreateProviderUploadResponseObject, error) {
	t, err := h.create(ctx, "provider", *req.Body)
	if err != nil {
		return nil, err
	}
	return api.CreateProviderUpload201JSONResponse(t), nil
}

// ConfirmProviderUpload implements POST /v1/provider/uploads/{mediaId}/confirm.
func (h *Handler) ConfirmProviderUpload(ctx context.Context, req api.ConfirmProviderUploadRequestObject) (api.ConfirmProviderUploadResponseObject, error) {
	o, err := h.confirm(ctx, req.MediaId)
	if err != nil {
		return nil, err
	}
	return api.ConfirmProviderUpload200JSONResponse(o), nil
}

// GetDocumentViewURL implements GET /v1/admin/documents/{mediaId}/view-url; the view
// is audited before the URL is handed out.
func (h *Handler) GetDocumentViewURL(ctx context.Context, req api.GetDocumentViewURLRequestObject) (api.GetDocumentViewURLResponseObject, error) {
	p, _ := httpx.PrincipalFrom(ctx)
	role := ""
	if len(p.Roles) > 0 {
		role = p.Roles[0]
	}
	url, exp, err := h.svc.ViewURL(ctx, req.MediaId, p.AccountID, role)
	if err != nil {
		return nil, errorMap.Map(err)
	}
	return api.GetDocumentViewURL200JSONResponse{Url: url, ExpiresAt: exp}, nil
}
