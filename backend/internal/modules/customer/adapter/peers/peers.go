// Package peers adapts other modules' contracts to the customer ports.
package peers

import (
	"context"
	"errors"

	"github.com/google/uuid"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/customer/domain"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
)

// Media implements port.Media.
type Media struct{ Svc media.MediaService }

// AttachAvatar implements port.Media.
func (m Media) AttachAvatar(ctx context.Context, owner, id uuid.UUID) error {
	o, err := m.Svc.GetObject(ctx, id)
	if errors.Is(err, media.ErrNotFound) || (err == nil && (o.OwnerID != owner || o.Purpose != media.PurposeAvatar || !o.Confirmed)) {
		return domain.ErrInvalidPhoto
	}
	if err != nil {
		return err
	}
	return m.Svc.MarkAttached(ctx, id)
}

// URL implements port.Media.
func (m Media) URL(ctx context.Context, viewer, id uuid.UUID) (string, error) {
	v, err := m.Svc.GetViewURL(ctx, media.ViewRequest{MediaID: id, ViewerID: viewer, ViewerRole: "customer"})
	return v.URL, err
}

// Accounts implements port.Accounts.
type Accounts struct{ Svc identity.IdentityService }

// Phone implements port.Accounts.
func (a Accounts) Phone(ctx context.Context, id uuid.UUID) (string, error) {
	acc, err := a.Svc.GetAccount(ctx, id)
	return acc.Phone, err
}

// Area implements port.Area.
type Area struct{ Svc admin.AdminService }

// ServiceArea implements port.Area.
func (a Area) ServiceArea(ctx context.Context) (string, error) {
	s, err := a.Svc.GetSettings(ctx)
	return s.ServiceAreaGeoJSON, err
}
