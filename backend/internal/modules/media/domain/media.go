// Package domain holds the upload rules per purpose (P04 task 4, PRD §6.6).
package domain

import (
	"errors"
	"slices"
	"time"

	"github.com/google/uuid"
)

// Media errors.
var (
	ErrInvalid     = errors.New("upload does not meet the rules for its purpose")
	ErrNotFound    = errors.New("media not found")
	ErrNotUploaded = errors.New("file missing or different from the request")
	ErrForbidden   = errors.New("this app may not upload that kind of file")
)

// Rule limits a purpose.
type Rule struct {
	ContentTypes []string
	MaxBytes     int64
	// Sensitive files are verification documents: every view is audited and they never
	// reach customer APIs.
	Sensitive bool
}

const mb = 1 << 20

var (
	images    = []string{"image/jpeg", "image/png"}
	documents = []string{"image/jpeg", "image/png", "application/pdf"}
	rules     = map[string]Rule{
		"avatar":           {ContentTypes: images, MaxBytes: 2 * mb},
		"complaint_photo":  {ContentTypes: images, MaxBytes: 5 * mb},
		"nid_front":        {ContentTypes: images, MaxBytes: 5 * mb, Sensitive: true},
		"nid_back":         {ContentTypes: images, MaxBytes: 5 * mb, Sensitive: true},
		"selfie":           {ContentTypes: images, MaxBytes: 5 * mb, Sensitive: true},
		"police_clearance": {ContentTypes: documents, MaxBytes: 5 * mb, Sensitive: true},
		"skill_proof":      {ContentTypes: documents, MaxBytes: 5 * mb, Sensitive: true},
		"address_proof":    {ContentTypes: documents, MaxBytes: 5 * mb, Sensitive: true},
		"level2_photo":     {ContentTypes: images, MaxBytes: 5 * mb, Sensitive: true},
	}
	// uploaders lists the purposes each app may upload.
	uploaders = map[string][]string{
		"customer": {"avatar", "complaint_photo"},
		"provider": {"avatar", "complaint_photo", "nid_front", "nid_back", "selfie", "police_clearance", "skill_proof", "address_proof"},
		"admin":    {"level2_photo"},
	}
)

// RuleFor returns the rule of a purpose.
func RuleFor(purpose string) (Rule, bool) {
	r, ok := rules[purpose]
	return r, ok
}

// CheckUpload validates who uploads what.
func CheckUpload(uploader, purpose, contentType string, size int64) error {
	if !slices.Contains(uploaders[uploader], purpose) {
		return ErrForbidden
	}
	r := rules[purpose]
	if !slices.Contains(r.ContentTypes, contentType) || size < 1 || size > r.MaxBytes {
		return ErrInvalid
	}
	return nil
}

// Object is a stored file's record.
type Object struct {
	ID          uuid.UUID
	OwnerID     uuid.UUID
	Purpose     string
	ContentType string
	SizeBytes   int64
	Bucket      string
	Key         string
	Confirmed   bool
	Attached    bool
	CreatedAt   time.Time
}

// ObjectKey places files by purpose and owner, so retention jobs can work per owner.
func ObjectKey(purpose string, owner, id uuid.UUID) string {
	return purpose + "/" + owner.String() + "/" + id.String()
}
