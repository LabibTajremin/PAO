// Package inproc implements the provider contract for other modules in the process.
package inproc

import (
	"context"
	"errors"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/geo"
	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Service adapts the provider use cases to contract.ProviderService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.ProviderService = (*Service)(nil)

func translate(err error) error {
	if errors.Is(err, domain.ErrNotFound) {
		return errors.Join(contract.ErrProviderNotFound, err)
	}
	return err
}

// GetProvider implements contract.ProviderService.
func (s *Service) GetProvider(ctx context.Context, id uuid.UUID) (contract.Provider, error) {
	p, err := s.svc.Get(ctx, id)
	if err != nil {
		return contract.Provider{}, translate(err)
	}
	out := contract.Provider{ID: p.ID, FullName: p.FullName, DateOfBirth: p.DateOfBirth, Gender: contract.Gender(p.Gender),
		PresentAddress: p.PresentAddress, PermanentAddress: p.PermanentAddress, Phone: p.Phone, PhotoMediaID: p.PhotoMediaID,
		ServiceIDs: p.ServiceIDs, ExperienceYears: p.ExperienceYears, WorkingRadiusM: p.WorkingRadiusM,
		Language: i18n.Language(p.Language), SubmittedAt: p.SubmittedAt}
	if p.HomeBase != nil {
		out.HomeBase = &geo.Point{Lat: p.HomeBase.Lat, Lng: p.HomeBase.Lng}
	}
	if p.Emergency.Phone != "" {
		e := contract.EmergencyContact(p.Emergency)
		out.EmergencyContact = &e
	}
	return out, nil
}

// IsAvailable implements contract.ProviderService.
func (s *Service) IsAvailable(ctx context.Context, id uuid.UUID) (bool, error) {
	return s.svc.IsAvailable(ctx, id)
}

// FindNearby implements contract.ProviderService.
func (s *Service) FindNearby(ctx context.Context, q contract.NearbyQuery) ([]contract.NearbyProvider, error) {
	found, err := s.svc.FindNearby(ctx, app.Nearby{ServiceID: q.ServiceID, At: domain.Point{Lat: q.Point.Lat, Lng: q.Point.Lng},
		RadiusM: q.RadiusM, WomenOnly: q.WomenProvidersOnly, ByRating: q.Sort == contract.SortRating, Limit: q.Limit})
	out := make([]contract.NearbyProvider, 0, len(found))
	for _, c := range found {
		out = append(out, contract.NearbyProvider{ProviderID: c.ID, Name: c.Name, PhotoMediaID: c.PhotoMediaID, Level: c.Level,
			Rating: c.Rating, RatingCount: c.RatingCount, CompletedJobs: c.CompletedJobs, DistanceM: c.DistanceM})
	}
	return out, translate(err)
}

// ForceOffline implements contract.ProviderService.
func (s *Service) ForceOffline(ctx context.Context, id uuid.UUID) error {
	return translate(s.svc.GoOffline(ctx, id, "forced"))
}

func status(p app.Progress, err error) (contract.EnrolmentStatus, error) {
	out := contract.EnrolmentStatus{Complete: p.Complete, Submitted: p.Submitted}
	for _, st := range p.Steps {
		out.Steps = append(out.Steps, contract.StepStatus{Step: contract.EnrolmentStep(st.Step), Done: st.Done, Required: st.Required})
	}
	return out, translate(err)
}

// Enrolment implements contract.ProviderService.
func (s *Service) Enrolment(ctx context.Context, id uuid.UUID) (contract.EnrolmentStatus, error) {
	return status(s.svc.Enrolment(ctx, id))
}

// MarkStepDone implements contract.ProviderService.
func (s *Service) MarkStepDone(ctx context.Context, id uuid.UUID, step contract.EnrolmentStep) (contract.EnrolmentStatus, error) {
	return status(s.svc.MarkStepDone(ctx, id, string(step)))
}

// MarkSubmitted implements contract.ProviderService.
func (s *Service) MarkSubmitted(ctx context.Context, id uuid.UUID) error {
	err := s.svc.MarkSubmitted(ctx, id)
	if errors.Is(err, domain.ErrIncomplete) {
		return errors.Join(contract.ErrEnrolmentIncomplete, err)
	}
	return err
}

// SearchProviders implements contract.ProviderService.
func (s *Service) SearchProviders(ctx context.Context, q contract.ProviderQuery) ([]contract.ProviderRecord, error) {
	return s.svc.Search(ctx, q)
}
