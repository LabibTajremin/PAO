package app

import (
	"context"
	"time"

	"github.com/google/uuid"

	provider "github.com/LabibTajremin/PAO/backend/internal/modules/provider/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/verification/domain"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// upload is one file of a document step.
type upload struct {
	kind  string
	media uuid.UUID
}

// submit attaches the uploads, puts the item into review and marks the wizard step.
func (s *Service) submit(ctx context.Context, id uuid.UUID, item string, files []upload, fields map[string]string,
	expires *time.Time, extra func(*domain.State)) (provider.EnrolmentStatus, error) {
	for _, f := range files {
		if err := s.d.Media.Attach(ctx, id, f.media, f.kind); err != nil {
			return provider.EnrolmentStatus{}, err
		}
	}
	now := s.d.Clock.Now()
	_, err := s.change(ctx, id, "resubmitted", func(st *domain.State) ([]eventbus.Event, error) {
		if extra != nil {
			extra(st)
		}
		it := st.Item(item)
		it.Submit(now, fields, expires)
		st.Items[item] = it
		for _, f := range files {
			st.NewDocuments = append(st.NewDocuments, domain.Document{ID: s.d.IDs.New(), ItemType: item, Kind: f.kind, MediaID: f.media, CreatedAt: now})
		}
		return nil, nil
	})
	if err != nil {
		return provider.EnrolmentStatus{}, err
	}
	return s.d.Providers.MarkStepDone(ctx, id, provider.EnrolmentStep(item))
}

// SaveNID stores the encrypted NID number with both sides of the card (M08). A number
// on the block list cannot enrol again (PRD §6.4).
func (s *Service) SaveNID(ctx context.Context, id uuid.UUID, number string, front, back uuid.UUID) (provider.EnrolmentStatus, error) {
	if !domain.ValidNID(number) {
		return provider.EnrolmentStatus{}, domain.ErrInvalid
	}
	hash := s.d.Cipher.LookupHash(number)
	blocked, err := s.d.Repo.NIDBlocked(ctx, hash)
	if err == nil && blocked {
		err = domain.ErrNIDBlocked
	}
	if err != nil {
		return provider.EnrolmentStatus{}, err
	}
	files := []upload{{"nid_front", front}, {"nid_back", back}}
	return s.submit(ctx, id, "nid", files, map[string]string{}, nil, func(st *domain.State) {
		st.NID, st.NIDChanged = &domain.NIDRecord{Ciphertext: s.d.Cipher.Encrypt([]byte(number)), Hash: hash}, true
	})
}

// SaveSelfie stores the live selfie (M09); a verifier compares it with the NID photo
// (D10: manual face match).
func (s *Service) SaveSelfie(ctx context.Context, id, media uuid.UUID) (provider.EnrolmentStatus, error) {
	return s.submit(ctx, id, "selfie", []upload{{"selfie", media}}, map[string]string{}, nil, nil)
}

// SavePoliceClearance stores the certificate; it must be under the validity period old
// and expires that long after its issue date (PRD §6.2 item 4, §6.4).
func (s *Service) SavePoliceClearance(ctx context.Context, id, media uuid.UUID, issued time.Time) (provider.EnrolmentStatus, error) {
	rules, err := s.d.Settings.Rules(ctx)
	if err != nil {
		return provider.EnrolmentStatus{}, err
	}
	expires, err := domain.ClearanceExpiry(issued, s.d.Clock.Now(), rules.PoliceClearanceValidity)
	if err != nil {
		return provider.EnrolmentStatus{}, err
	}
	fields := map[string]string{"issueDate": issued.Format(time.DateOnly)}
	return s.submit(ctx, id, "police_clearance", []upload{{"police_clearance", media}}, fields, &expires, nil)
}

// SaveSkillProof stores optional certificates or work photos (PRD §6.2 item 7).
func (s *Service) SaveSkillProof(ctx context.Context, id uuid.UUID, media []uuid.UUID) (provider.EnrolmentStatus, error) {
	if len(media) == 0 || len(media) > 10 {
		return provider.EnrolmentStatus{}, domain.ErrInvalid
	}
	files := make([]upload, 0, len(media))
	for _, m := range media {
		files = append(files, upload{"skill_proof", m})
	}
	return s.submit(ctx, id, "skill_proof", files, map[string]string{}, nil, nil)
}
