package app

import (
	"context"
	"strings"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// profileSteps are saved here and reported to verification, which re-reviews the
// matching item (PRD §6.4: changed data is checked again).
var profileSteps = map[string]bool{"personal": true, "services": true, "area": true, "emergency_contact": true, "code_of_conduct": true}

// update loads the provider, applies change, marks step done and saves.
func (s *Service) update(ctx context.Context, id uuid.UUID, step string, change func(*domain.Provider) error) (Progress, error) {
	p, err := s.load(ctx, id)
	if err == nil {
		err = change(&p)
	}
	if err != nil {
		return Progress{}, err
	}
	var events []eventbus.Event
	if step != "" {
		p.StepsDone = domain.WithStep(p.StepsDone, step)
		if profileSteps[step] {
			events = append(events, contract.EnrolmentStepSaved{ProviderID: id, Step: contract.EnrolmentStep(step)})
		}
	}
	if err := s.d.Repo.Save(ctx, p, events...); err != nil {
		return Progress{}, err
	}
	return progressOf(p), nil
}

// SavePersonal saves the M05 step.
func (s *Service) SavePersonal(ctx context.Context, id uuid.UUID, in domain.Personal) (Progress, error) {
	if err := in.Validate(s.d.Clock.Now()); err != nil {
		return Progress{}, err
	}
	return s.update(ctx, id, "personal", func(p *domain.Provider) error {
		dob := in.DateOfBirth
		p.FullName, p.DateOfBirth, p.Gender = strings.TrimSpace(in.FullName), &dob, in.Gender
		p.PresentAddress, p.PermanentAddress, p.Bio = in.PresentAddress, in.PermanentAddress, in.Bio
		return nil
	})
}

// SaveServices saves the M06 step. Changing services takes the provider offline, so
// the presence index never lists them under a service they dropped.
func (s *Service) SaveServices(ctx context.Context, id uuid.UUID, services []uuid.UUID, experienceYears int) (Progress, error) {
	if err := domain.ValidateServices(len(services), experienceYears); err != nil {
		return Progress{}, err
	}
	for _, sid := range services {
		svc, err := s.d.Catalog.Service(ctx, sid)
		if err == nil && !svc.Published {
			err = domain.ErrUnknownService
		}
		if err != nil {
			return Progress{}, err
		}
	}
	return s.update(ctx, id, "services", func(p *domain.Provider) error {
		if err := s.d.Presence.Offline(ctx, id, p.ServiceIDs); err != nil {
			return err
		}
		p.ServiceIDs, p.ExperienceYears = services, experienceYears
		return nil
	})
}

// SaveArea saves the M07 step.
func (s *Service) SaveArea(ctx context.Context, id uuid.UUID, home domain.Point, radiusM int) (Progress, error) {
	if err := domain.ValidateArea(home, radiusM); err != nil {
		return Progress{}, err
	}
	return s.update(ctx, id, "area", func(p *domain.Provider) error {
		p.HomeBase, p.WorkingRadiusM = &home, radiusM
		return nil
	})
}

// SaveEmergencyContact stores the guarantor and sends them a code; the step is done
// only after VerifyEmergencyContact (PRD §6.2 item 6).
func (s *Service) SaveEmergencyContact(ctx context.Context, id uuid.UUID, c domain.EmergencyContact) (Progress, error) {
	phone, ok := domain.NormalizePhone(c.Phone)
	if !ok {
		return Progress{}, domain.ErrInvalid
	}
	c.Phone, c.VerifiedAt = phone, nil
	return s.update(ctx, id, "", func(p *domain.Provider) error {
		if err := c.Validate(p.Phone); err != nil {
			return err
		}
		p.Emergency = c
		p.StepsDone = without(p.StepsDone, "emergency_contact")
		return s.d.Accounts.SendContactCode(ctx, phone)
	})
}

func without(steps []string, step string) []string {
	out := make([]string, 0, len(steps))
	for _, s := range steps {
		if s != step {
			out = append(out, s)
		}
	}
	return out
}

// VerifyEmergencyContact checks the code sent to the guarantor.
func (s *Service) VerifyEmergencyContact(ctx context.Context, id uuid.UUID, code string) (Progress, error) {
	return s.update(ctx, id, "emergency_contact", func(p *domain.Provider) error {
		if p.Emergency.Phone == "" {
			return domain.ErrContactUnproven
		}
		if err := s.d.Accounts.CheckContactCode(ctx, p.Emergency.Phone, code); err != nil {
			return err
		}
		now := s.d.Clock.Now()
		p.Emergency.VerifiedAt = &now
		return nil
	})
}

// AcceptCodeOfConduct records the accepted version with a timestamp (PRD §6.2 item 9).
func (s *Service) AcceptCodeOfConduct(ctx context.Context, id uuid.UUID, version string, accepted bool) (Progress, error) {
	if !accepted || strings.TrimSpace(version) == "" {
		return Progress{}, domain.ErrInvalid
	}
	return s.update(ctx, id, "code_of_conduct", func(p *domain.Provider) error {
		now := s.d.Clock.Now()
		p.CoCVersion, p.CoCAcceptedAt = version, &now
		return nil
	})
}
