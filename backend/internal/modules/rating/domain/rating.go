// Package domain holds two-way reviews and their aggregates (C-11, P-09).
package domain

import (
	"errors"
	"slices"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
)

// Rating errors.
var (
	ErrNotAllowed      = errors.New("this booking cannot be reviewed by you")
	ErrAlreadyReviewed = errors.New("you already reviewed this booking")
	ErrInvalid         = errors.New("review is not valid")
)

// Roles.
const (
	Customer = "customer"
	Provider = "provider"
)

// Text is a value in English and Bangla.
type Text struct {
	EN string
	BN string
}

// Reviewable is a completed booking; only these may be reviewed.
type Reviewable struct {
	BookingID    uuid.UUID
	CustomerID   uuid.UUID
	ProviderID   uuid.UUID
	CustomerName string
	ProviderName string
	ServiceName  Text
	CompletedAt  time.Time
}

// Review is one side's rating of the other.
type Review struct {
	ID          uuid.UUID
	BookingID   uuid.UUID
	AuthorID    uuid.UUID
	AuthorRole  string
	AuthorName  string
	SubjectID   uuid.UUID
	Stars       int
	Tags        []string
	Comment     string
	ServiceName Text
	CreatedAt   time.Time
}

// SubjectRole is the role of the person being reviewed.
func (r Review) SubjectRole() string {
	if r.AuthorRole == Customer {
		return Provider
	}
	return Customer
}

// NewReview checks eligibility (a party of a completed booking) and the content:
// 1–5 stars, at most six distinct tags, a comment of at most 500 characters.
func NewReview(b Reviewable, author uuid.UUID, role string, stars int, tags []string, comment string) (Review, error) {
	r := Review{BookingID: b.BookingID, AuthorID: author, AuthorRole: role, Stars: stars, Tags: tags, Comment: strings.TrimSpace(comment),
		ServiceName: b.ServiceName}
	switch {
	case role == Customer && author == b.CustomerID:
		r.AuthorName, r.SubjectID = FirstName(b.CustomerName), b.ProviderID
	case role == Provider && author == b.ProviderID:
		r.AuthorName, r.SubjectID = FirstName(b.ProviderName), b.CustomerID
	default:
		return Review{}, ErrNotAllowed
	}
	if !valid(stars, tags, r.Comment) {
		return Review{}, ErrInvalid
	}
	if r.Tags == nil {
		r.Tags = []string{}
	}
	return r, nil
}

// valid allows 1–5 stars, at most six distinct tags and 500 characters of comment.
func valid(stars int, tags []string, comment string) bool {
	sorted := slices.Clone(tags)
	slices.Sort(sorted)
	distinct := len(slices.Compact(sorted)) == len(tags)
	return stars >= 1 && stars <= 5 && len(tags) <= 6 && distinct && utf8.RuneCountInString(comment) <= 500
}

// FirstName keeps reviewers' privacy: only the first word of the name is shown.
func FirstName(name string) string {
	if f := strings.Fields(name); len(f) > 0 {
		return f[0]
	}
	return ""
}

// Aggregate is an incrementally updated rating summary.
type Aggregate struct {
	Count        int
	Sum          int64
	Distribution [5]int
}

// Average returns the mean rating rounded to one decimal, 0 when unrated.
func (a Aggregate) Average() float64 {
	if a.Count == 0 {
		return 0
	}
	return float64(int64(float64(a.Sum)/float64(a.Count)*10+0.5)) / 10
}
