package contract

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

// Purpose decides a file's bucket, allowed types and size limit.
type Purpose string

// Upload purposes.
const (
	PurposeAvatar          Purpose = "avatar"
	PurposeNIDFront        Purpose = "nid_front"
	PurposeNIDBack         Purpose = "nid_back"
	PurposeSelfie          Purpose = "selfie"
	PurposePoliceClearance Purpose = "police_clearance"
	PurposeSkillProof      Purpose = "skill_proof"
	PurposeAddressProof    Purpose = "address_proof"
	PurposeComplaintPhoto  Purpose = "complaint_photo"
	PurposeLevel2Photo     Purpose = "level2_photo"
)

// UploadRequest asks for a presigned upload URL.
type UploadRequest struct {
	OwnerID     uuid.UUID
	Purpose     Purpose
	ContentType string
	SizeBytes   int64
}

// UploadTicket tells the client where and how to PUT the file.
type UploadTicket struct {
	MediaID   uuid.UUID
	URL       string
	Headers   map[string]string
	ExpiresAt time.Time
}

// Object is a stored file's metadata.
type Object struct {
	ID          uuid.UUID
	OwnerID     uuid.UUID
	Purpose     Purpose
	ContentType string
	SizeBytes   int64
	Confirmed   bool
}

// ViewRequest asks to see a file. Viewer details feed the audit entry.
type ViewRequest struct {
	MediaID    uuid.UUID
	ViewerID   uuid.UUID
	ViewerRole string
}

// ViewURL is a short-lived signed URL.
type ViewURL struct {
	URL       string
	ExpiresAt time.Time
}

// Errors returned through the contract.
var (
	ErrUploadInvalid = errors.New("upload does not meet the purpose's rules")
	ErrNotFound      = errors.New("media not found")
	ErrNotUploaded   = errors.New("object missing or different from the request")
)
