package domain

import (
	"sort"

	"github.com/google/uuid"
)

// Candidate is a provider found near a customer.
type Candidate struct {
	ID            uuid.UUID
	Name          string
	PhotoMediaID  *uuid.UUID
	Gender        string
	Level         int
	Rating        float64
	RatingCount   int
	CompletedJobs int
	DistanceM     int
}

// Rank orders candidates Level 2 first, then by distance or rating (PRD §5); ties fall
// back to distance so the order is stable.
func Rank(c []Candidate, byRating bool) {
	sort.SliceStable(c, func(i, j int) bool {
		a, b := c[i], c[j]
		if (a.Level >= 2) != (b.Level >= 2) {
			return a.Level >= 2
		}
		if byRating && a.Rating != b.Rating {
			return a.Rating > b.Rating
		}
		return a.DistanceM < b.DistanceM
	})
}
