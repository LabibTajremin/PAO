package contract

import (
	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/platform/i18n"
)

// Channel is a delivery route.
type Channel string

// Channels. SMS is reserved for OTP and critical messages (P08).
const (
	ChannelPush  Channel = "push"
	ChannelSMS   Channel = "sms"
	ChannelInbox Channel = "inbox"
)

// Message asks for one notification.
type Message struct {
	RecipientID uuid.UUID
	// App selects the device tokens: "customer" or "partner".
	App       string
	Language  i18n.Language
	Template  string
	Data      map[string]string
	BookingID *uuid.UUID
	Channels  []Channel
	// DedupeKey makes redelivered events notify once.
	DedupeKey string
}
