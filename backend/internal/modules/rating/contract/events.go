package contract

import "github.com/google/uuid"

// ReviewSubmitted is published after a review is stored, carrying the new aggregate so
// subscribers (search ranking, quality review) need not call back.
type ReviewSubmitted struct {
	ReviewID    uuid.UUID
	BookingID   uuid.UUID
	AuthorID    uuid.UUID
	SubjectID   uuid.UUID
	SubjectRole string
	Stars       int
	NewAverage  float64
	NewCount    int
}

// EventName implements eventbus.Event.
func (ReviewSubmitted) EventName() string { return "rating.ReviewSubmitted" }
