// Package inproc implements the media contract for other modules in the process.
package inproc

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/media/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/domain"
)

// Service adapts the media use cases to contract.MediaService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.MediaService = (*Service)(nil)

func translate(err error) error {
	switch {
	case errors.Is(err, domain.ErrNotFound):
		return errors.Join(contract.ErrNotFound, err)
	case errors.Is(err, domain.ErrInvalid), errors.Is(err, domain.ErrForbidden):
		return errors.Join(contract.ErrUploadInvalid, err)
	case errors.Is(err, domain.ErrNotUploaded):
		return errors.Join(contract.ErrNotUploaded, err)
	}
	return err
}

func toObject(o domain.Object) contract.Object {
	return contract.Object{ID: o.ID, OwnerID: o.OwnerID, Purpose: contract.Purpose(o.Purpose), ContentType: o.ContentType,
		SizeBytes: o.SizeBytes, Confirmed: o.Confirmed}
}

// CreateUploadURL implements contract.MediaService for uploads made by other modules,
// such as Level 2 visit photos recorded by verifiers.
func (s *Service) CreateUploadURL(ctx context.Context, req contract.UploadRequest) (contract.UploadTicket, error) {
	t, err := s.svc.CreateUpload(ctx, req.OwnerID, "admin", string(req.Purpose), req.ContentType, req.SizeBytes)
	return contract.UploadTicket{MediaID: t.MediaID, URL: t.URL, Headers: t.Headers, ExpiresAt: t.ExpiresAt}, translate(err)
}

// ConfirmUpload implements contract.MediaService.
func (s *Service) ConfirmUpload(ctx context.Context, owner, id uuid.UUID) (contract.Object, error) {
	o, err := s.svc.Confirm(ctx, owner, id)
	return toObject(o), translate(err)
}

// GetObject implements contract.MediaService.
func (s *Service) GetObject(ctx context.Context, id uuid.UUID) (contract.Object, error) {
	o, err := s.svc.Get(ctx, id)
	return toObject(o), translate(err)
}

// MarkAttached implements contract.MediaService.
func (s *Service) MarkAttached(ctx context.Context, id uuid.UUID) error {
	return translate(s.svc.MarkAttached(ctx, id))
}

// GetViewURL implements contract.MediaService.
func (s *Service) GetViewURL(ctx context.Context, req contract.ViewRequest) (contract.ViewURL, error) {
	url, exp, err := s.svc.ViewURL(ctx, req.MediaID, req.ViewerID, req.ViewerRole)
	return contract.ViewURL{URL: url, ExpiresAt: exp}, translate(err)
}

// Delete implements contract.MediaService.
func (s *Service) Delete(ctx context.Context, id uuid.UUID) error {
	return translate(s.svc.Delete(ctx, id))
}
