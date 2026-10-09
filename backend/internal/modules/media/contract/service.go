// Package contract is the media module's public surface (PRD §9.3 rule 1).
package contract

import (
	"context"

	"github.com/google/uuid"
)

// MediaService is what other modules may ask of the media module.
type MediaService interface {
	// CreateUploadURL validates the request against the purpose's rules and returns a
	// presigned PUT URL (documents: JPEG/PNG/PDF ≤ 5 MB; avatars: JPEG/PNG ≤ 2 MB).
	CreateUploadURL(ctx context.Context, req UploadRequest) (UploadTicket, error)
	// ConfirmUpload checks that the object exists and matches the request.
	ConfirmUpload(ctx context.Context, ownerID, mediaID uuid.UUID) (Object, error)
	// GetObject returns metadata, so callers can check owner and purpose before attaching.
	GetObject(ctx context.Context, mediaID uuid.UUID) (Object, error)
	// MarkAttached records that a record references the object, sparing it from the
	// orphan purge.
	MarkAttached(ctx context.Context, mediaID uuid.UUID) error
	// GetViewURL returns a 5-minute signed GET URL. Viewing a verification document
	// writes an audit entry (PRD §6.6).
	GetViewURL(ctx context.Context, req ViewRequest) (ViewURL, error)
	// Delete removes the object from storage and its record.
	Delete(ctx context.Context, mediaID uuid.UUID) error
}
