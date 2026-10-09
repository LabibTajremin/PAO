// Package app holds the media use cases: signed uploads, confirmation, audited views and
// the orphan purge.
package app

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"

	audit "github.com/LabibTajremin/PAO/backend/internal/modules/audit/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/media/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/clock"
	"github.com/LabibTajremin/PAO/backend/internal/platform/idgen"
	"github.com/LabibTajremin/PAO/backend/internal/platform/storage"
)

// Lifetimes of signed URLs and of unattached uploads.
const (
	UploadURLTTL = 15 * time.Minute
	ViewURLTTL   = 5 * time.Minute
	OrphanAfter  = 24 * time.Hour
)

// Deps are the media collaborators.
type Deps struct {
	Repo    port.Repository
	Storage port.Storage
	Auditor port.Auditor
	Bucket  string
	Clock   clock.Clock
	IDs     idgen.Generator
}

// Service implements the media use cases.
type Service struct{ d Deps }

// New returns the media service.
func New(d Deps) *Service { return &Service{d: d} }

// Ticket tells a client where to PUT a file.
type Ticket struct {
	MediaID   uuid.UUID
	URL       string
	Headers   map[string]string
	ExpiresAt time.Time
}

// CreateUpload validates the request and returns a presigned PUT URL. uploader is
// "customer", "provider" or "admin".
func (s *Service) CreateUpload(ctx context.Context, owner uuid.UUID, uploader, purpose, contentType string, size int64) (Ticket, error) {
	if err := domain.CheckUpload(uploader, purpose, contentType, size); err != nil {
		return Ticket{}, err
	}
	id := s.d.IDs.New()
	o := domain.Object{ID: id, OwnerID: owner, Purpose: purpose, ContentType: contentType, SizeBytes: size,
		Bucket: s.d.Bucket, Key: domain.ObjectKey(purpose, owner, id), CreatedAt: s.d.Clock.Now()}
	if err := s.d.Repo.Create(ctx, o); err != nil {
		return Ticket{}, err
	}
	url, headers, err := s.d.Storage.PresignPut(ctx, o.Bucket, o.Key, contentType, size, UploadURLTTL)
	if err != nil {
		return Ticket{}, err
	}
	return Ticket{MediaID: id, URL: url, Headers: headers, ExpiresAt: o.CreatedAt.Add(UploadURLTTL)}, nil
}

// Confirm checks that the owner's file arrived with the declared type and size.
func (s *Service) Confirm(ctx context.Context, owner, id uuid.UUID) (domain.Object, error) {
	o, err := s.d.Repo.Get(ctx, id)
	if err == nil && o.OwnerID != owner {
		err = domain.ErrNotFound
	}
	if err != nil {
		return domain.Object{}, err
	}
	if o.Confirmed {
		return o, nil
	}
	info, err := s.d.Storage.Head(ctx, o.Bucket, o.Key)
	if errors.Is(err, storage.ErrObjectNotFound) {
		return domain.Object{}, domain.ErrNotUploaded
	}
	if err != nil {
		return domain.Object{}, err
	}
	if info.Size != o.SizeBytes || info.ContentType != o.ContentType {
		return domain.Object{}, errors.Join(domain.ErrNotUploaded, s.d.Storage.Delete(ctx, o.Bucket, o.Key))
	}
	o.Confirmed = true
	return o, s.d.Repo.MarkConfirmed(ctx, id)
}

// Get returns an object's record.
func (s *Service) Get(ctx context.Context, id uuid.UUID) (domain.Object, error) {
	return s.d.Repo.Get(ctx, id)
}

// MarkAttached spares an object from the orphan purge.
func (s *Service) MarkAttached(ctx context.Context, id uuid.UUID) error {
	return s.d.Repo.MarkAttached(ctx, id)
}

// ViewURL returns a 5-minute signed URL. Viewing a verification document writes an
// audit entry first, so no view goes unrecorded (PRD §6.6).
func (s *Service) ViewURL(ctx context.Context, id, viewer uuid.UUID, viewerRole string) (string, time.Time, error) {
	o, err := s.d.Repo.Get(ctx, id)
	if err != nil {
		return "", time.Time{}, err
	}
	if !o.Confirmed {
		return "", time.Time{}, domain.ErrNotFound
	}
	if rule, _ := domain.RuleFor(o.Purpose); rule.Sensitive {
		err := s.d.Auditor.Record(ctx, audit.Entry{ActorID: &viewer, ActorRole: viewerRole, Action: "media.document_viewed",
			SubjectType: "media", SubjectID: id.String(), After: map[string]any{"purpose": o.Purpose, "owner": o.OwnerID.String()}})
		if err != nil {
			return "", time.Time{}, fmt.Errorf("audit document view: %w", err)
		}
	}
	url, err := s.d.Storage.PresignGet(ctx, o.Bucket, o.Key, ViewURLTTL)
	return url, s.d.Clock.Now().Add(ViewURLTTL), err
}

// Delete removes the file and its record.
func (s *Service) Delete(ctx context.Context, id uuid.UUID) error {
	o, err := s.d.Repo.Get(ctx, id)
	if err != nil {
		return err
	}
	if err := s.d.Storage.Delete(ctx, o.Bucket, o.Key); err != nil {
		return err
	}
	return s.d.Repo.Delete(ctx, id)
}

// PurgeOrphans deletes uploads never attached to a record within a day.
func (s *Service) PurgeOrphans(ctx context.Context) (int, error) {
	orphans, err := s.d.Repo.Orphans(ctx, s.d.Clock.Now().Add(-OrphanAfter))
	if err != nil {
		return 0, err
	}
	for i, o := range orphans {
		if err := s.Delete(ctx, o.ID); err != nil {
			return i, err
		}
	}
	return len(orphans), nil
}
