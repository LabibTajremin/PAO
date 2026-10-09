// Package peers adapts other modules' contracts to the provider ports.
package peers

import (
	"context"
	"errors"

	"github.com/google/uuid"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	catalog "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	media "github.com/LabibTajremin/PAO/backend/internal/modules/media/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/port"
)

// Catalog implements port.Catalog.
type Catalog struct{ Svc catalog.CatalogService }

// Service implements port.Catalog. The minimum level is the service's required level,
// raised to 2 when the service demands Level 2 (PRD §6.1).
func (c Catalog) Service(ctx context.Context, id uuid.UUID) (port.Service, error) {
	s, err := c.Svc.GetService(ctx, id)
	if errors.Is(err, catalog.ErrServiceNotFound) {
		return port.Service{}, domain.ErrUnknownService
	}
	minLevel := s.RequiredLevel
	if s.RequiresLevel2 {
		minLevel = 2
	}
	return port.Service{ID: s.ID, Name: s.Name, Published: s.Published, MinLevel: minLevel, WomenProvidersOnly: s.WomenProvidersOnly}, err
}

// Accounts implements port.Accounts.
type Accounts struct{ Svc identity.IdentityService }

// Phone implements port.Accounts.
func (a Accounts) Phone(ctx context.Context, id uuid.UUID) (string, error) {
	acc, err := a.Svc.GetAccount(ctx, id)
	return acc.Phone, err
}

func codeError(err error) error {
	switch {
	case errors.Is(err, identity.ErrRateLimited):
		return errors.Join(domain.ErrCodeRateLimited, err)
	case errors.Is(err, identity.ErrCodeInvalid), errors.Is(err, identity.ErrCodeExpired), errors.Is(err, identity.ErrCodeLocked):
		return errors.Join(domain.ErrCodeRejected, err)
	}
	return err
}

// SendContactCode implements port.Accounts.
func (a Accounts) SendContactCode(ctx context.Context, phone string) error {
	return codeError(a.Svc.SendPhoneCode(ctx, phone, identity.PurposeEmergencyContact))
}

// CheckContactCode implements port.Accounts.
func (a Accounts) CheckContactCode(ctx context.Context, phone, code string) error {
	return codeError(a.Svc.CheckPhoneCode(ctx, phone, identity.PurposeEmergencyContact, code))
}

// Media implements port.Media.
type Media struct{ Svc media.MediaService }

// AttachAvatar implements port.Media.
func (m Media) AttachAvatar(ctx context.Context, owner, id uuid.UUID) error {
	o, err := m.Svc.GetObject(ctx, id)
	if errors.Is(err, media.ErrNotFound) || (err == nil && (o.OwnerID != owner || o.Purpose != media.PurposeAvatar || !o.Confirmed)) {
		return domain.ErrInvalidPhoto
	}
	if err == nil {
		err = m.Svc.MarkAttached(ctx, id)
	}
	return err
}

// URL implements port.Media.
func (m Media) URL(ctx context.Context, viewer, id uuid.UUID) (string, error) {
	v, err := m.Svc.GetViewURL(ctx, media.ViewRequest{MediaID: id, ViewerID: viewer, ViewerRole: "provider"})
	return v.URL, err
}

// Settings implements port.Settings.
type Settings struct{ Svc admin.AdminService }

// Quality implements port.Settings.
func (s Settings) Quality(ctx context.Context) (port.Quality, error) {
	v, err := s.Svc.GetSettings(ctx)
	return port.Quality{RatingFloor: v.RatingFloor, RatingMinJobs: v.RatingMinJobs, MaxCancellations: v.MaxProviderCancellations30d}, err
}
