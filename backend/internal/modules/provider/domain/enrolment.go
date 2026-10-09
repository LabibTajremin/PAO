package domain

import (
	"slices"
	"strings"
	"time"
	"unicode/utf8"
)

// Steps lists the enrolment wizard in order (M05–M13).
var Steps = []string{"personal", "services", "area", "nid", "selfie", "police_clearance", "skill_proof", "emergency_contact", "code_of_conduct"}

// StepStatus is one step's progress.
type StepStatus struct {
	Step     string
	Done     bool
	Required bool
}

// Progress returns every step's status and whether all required ones are done. Skill
// proof is optional for Level 1 (PRD §6.2 item 7).
func Progress(done []string) ([]StepStatus, bool) {
	out := make([]StepStatus, 0, len(Steps))
	complete := true
	for _, s := range Steps {
		st := StepStatus{Step: s, Done: slices.Contains(done, s), Required: s != "skill_proof"}
		complete = complete && (st.Done || !st.Required)
		out = append(out, st)
	}
	return out, complete
}

// WithStep adds a step to the done list once.
func WithStep(done []string, step string) []string {
	if slices.Contains(done, step) {
		return done
	}
	return append(slices.Clone(done), step)
}

func between(s string, lo, hi int) bool {
	n := utf8.RuneCountInString(strings.TrimSpace(s))
	return n >= lo && n <= hi
}

// Personal holds the M05 fields.
type Personal struct {
	FullName         string
	DateOfBirth      time.Time
	Gender           string
	PresentAddress   string
	PermanentAddress string
	Bio              string
}

// Validate checks the personal step; the provider must be 18 on the given day.
func (p Personal) Validate(today time.Time) error {
	if !between(p.FullName, 3, 100) || !between(p.PresentAddress, 5, 300) || !between(p.PermanentAddress, 5, 300) ||
		utf8.RuneCountInString(p.Bio) > 500 || !slices.Contains([]string{"female", "male", "other"}, p.Gender) {
		return ErrInvalid
	}
	if p.DateOfBirth.AddDate(18, 0, 0).After(today) {
		return ErrTooYoung
	}
	return nil
}

// ValidateServices checks the M06 step: one to five services and plausible experience.
func ValidateServices(count, experienceYears int) error {
	if count < 1 || count > 5 || experienceYears < 0 || experienceYears > 60 {
		return ErrInvalid
	}
	return nil
}

// ValidateArea checks the M07 step: a home base in Bangladesh and a 1–30 km radius.
func ValidateArea(p Point, radiusM int) error {
	inBD := p.Lat >= 20.5 && p.Lat <= 26.7 && p.Lng >= 88.0 && p.Lng <= 92.7
	if !inBD || radiusM < 1000 || radiusM > 30000 {
		return ErrInvalid
	}
	return nil
}

// Validate checks the emergency contact; it must be someone else's phone.
func (e EmergencyContact) Validate(ownPhone string) error {
	if !between(e.Name, 2, 80) || !between(e.Relation, 2, 40) || e.Phone == "" || e.Phone == ownPhone {
		return ErrInvalid
	}
	return nil
}

// NormalizePhone returns a Bangladeshi mobile number as +8801XXXXXXXXX; the API
// accepts the local and international spellings.
func NormalizePhone(s string) (string, bool) {
	s = strings.TrimPrefix(strings.TrimPrefix(s, "+"), "880")
	s = strings.TrimPrefix(s, "0")
	if len(s) != 10 || s[0] != '1' || s[1] < '3' {
		return "", false
	}
	for _, r := range s {
		if r < '0' || r > '9' {
			return "", false
		}
	}
	return "+880" + s, true
}
