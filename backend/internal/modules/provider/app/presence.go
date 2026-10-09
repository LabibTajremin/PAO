package app

import (
	"context"
	"unicode/utf8"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/provider/port"
)

// HeartbeatEvery is how often an online app reports its position.
const HeartbeatEvery = 30

// GoOnline puts a verified provider into the presence index at their position.
func (s *Service) GoOnline(ctx context.Context, id uuid.UUID, at domain.Point) error {
	p, err := s.d.Repo.Get(ctx, id)
	if err == nil {
		err = p.CanGoOnline()
	}
	if err != nil {
		return err
	}
	return s.d.Presence.Online(ctx, id, p.ServiceIDs, at)
}

// Heartbeat refreshes an online provider's position.
func (s *Service) Heartbeat(ctx context.Context, id uuid.UUID, at domain.Point) error {
	p, err := s.d.Repo.Get(ctx, id)
	if err != nil {
		return err
	}
	return s.d.Presence.Beat(ctx, id, p.ServiceIDs, at)
}

// GoOffline removes the provider from presence; their position is dropped with it.
func (s *Service) GoOffline(ctx context.Context, id uuid.UUID, reason string) error {
	p, err := s.d.Repo.Get(ctx, id)
	if err == nil {
		err = s.d.Presence.Offline(ctx, id, p.ServiceIDs)
	}
	if err != nil {
		return err
	}
	return s.d.Repo.Publish(ctx, id, contract.ProviderWentOffline{ProviderID: id, Reason: reason})
}

// ReapLost takes providers whose heartbeat lapsed offline.
func (s *Service) ReapLost(ctx context.Context) error {
	ids, err := s.d.Presence.Lost(ctx)
	for _, id := range ids {
		if err == nil {
			err = s.GoOffline(ctx, id, "heartbeat_lost")
		}
	}
	return err
}

// Profile is the provider's own view (M28).
type Profile struct {
	domain.Provider
	Online   bool
	PhotoURL string
	Services []port.Service
}

// Profile returns the provider's profile with presence and photo.
func (s *Service) Profile(ctx context.Context, id uuid.UUID) (Profile, error) {
	p, err := s.load(ctx, id)
	if err != nil {
		return Profile{}, err
	}
	out := Profile{Provider: p}
	out.Online, err = s.d.Presence.IsOnline(ctx, id)
	if err == nil && p.PhotoMediaID != nil {
		out.PhotoURL, err = s.d.Media.URL(ctx, id, *p.PhotoMediaID)
	}
	for _, sid := range p.ServiceIDs {
		var svc port.Service
		if err == nil {
			svc, err = s.d.Catalog.Service(ctx, sid)
			out.Services = append(out.Services, svc)
		}
	}
	return out, err
}

// UpdateProfile changes the bio, photo and language (M28).
func (s *Service) UpdateProfile(ctx context.Context, id uuid.UUID, bio string, photo *uuid.UUID, language string) (Profile, error) {
	if utf8.RuneCountInString(bio) > 500 || (language != "en" && language != "bn") {
		return Profile{}, domain.ErrInvalid
	}
	_, err := s.update(ctx, id, "", func(p *domain.Provider) error {
		if photo != nil {
			if err := s.d.Media.AttachAvatar(ctx, id, *photo); err != nil {
				return err
			}
		}
		p.Bio, p.PhotoMediaID, p.Language = bio, photo, language
		return nil
	})
	if err != nil {
		return Profile{}, err
	}
	return s.Profile(ctx, id)
}

// Nearby is a search for providers around a customer.
type Nearby struct {
	ServiceID uuid.UUID
	At        domain.Point
	RadiusM   int
	WomenOnly bool
	ByRating  bool
	Limit     int
}

// FindNearby returns online providers who may take the service, within both the
// search radius and their own working radius, Level 2 first (PRD §5, D11).
func (s *Service) FindNearby(ctx context.Context, q Nearby) ([]domain.Candidate, error) {
	svc, err := s.d.Catalog.Service(ctx, q.ServiceID)
	if err != nil {
		return nil, err
	}
	hits, err := s.d.Presence.Near(ctx, q.ServiceID, q.At, q.RadiusM)
	if err != nil || len(hits) == 0 {
		return []domain.Candidate{}, err
	}
	dist := make(map[uuid.UUID]int, len(hits))
	ids := make([]uuid.UUID, 0, len(hits))
	for _, h := range hits {
		dist[h.ID] = h.DistanceM
		ids = append(ids, h.ID)
	}
	rows, err := s.d.Repo.Candidates(ctx, ids, max(1, svc.MinLevel))
	out := eligible(rows, dist, q.WomenOnly || svc.WomenProvidersOnly)
	domain.Rank(out, q.ByRating)
	if q.Limit > 0 && len(out) > q.Limit {
		out = out[:q.Limit]
	}
	return out, err
}

// eligible keeps candidates within their own working radius and, for women-only
// services, women providers (D11).
func eligible(rows []port.Candidate, dist map[uuid.UUID]int, womenOnly bool) []domain.Candidate {
	out := make([]domain.Candidate, 0, len(rows))
	for _, r := range rows {
		r.DistanceM = dist[r.ID]
		if r.DistanceM <= r.WorkingRadiusM && (!womenOnly || r.Gender == "female") {
			out = append(out, r.Candidate)
		}
	}
	return out
}

// PublicProfile is what customers see of a provider (C11): never documents or contacts.
type PublicProfile struct {
	Profile
	Rating port.Rating
}

// PublicProfile returns a verified provider's public profile.
func (s *Service) PublicProfile(ctx context.Context, viewer, id uuid.UUID) (PublicProfile, error) {
	p, err := s.d.Repo.Get(ctx, id)
	if err == nil && (p.Level < 1 || p.AccountStatus != "active") {
		err = domain.ErrNotFound
	}
	out := PublicProfile{Profile: Profile{Provider: p}}
	if err == nil && p.PhotoMediaID != nil {
		out.PhotoURL, err = s.d.Media.URL(ctx, viewer, *p.PhotoMediaID)
	}
	for _, sid := range p.ServiceIDs {
		var svc port.Service
		if err == nil {
			svc, err = s.d.Catalog.Service(ctx, sid)
			out.Services = append(out.Services, svc)
		}
	}
	if err == nil {
		out.Rating, err = s.d.Ratings.ProviderRating(ctx, id)
	}
	return out, err
}
