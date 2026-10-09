// Package inproc implements the admin contract for other modules in the process.
package inproc

import (
	"context"
	"strconv"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
)

// Service adapts the admin use cases to contract.AdminService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.AdminService = (*Service)(nil)

// defaults mirror the seeded rows (docs/build/04-decisions.md), so a missing or
// damaged row cannot stop bookings.
var defaults = map[string]string{
	"booking.accept_timeout_asap_seconds":         "180",
	"booking.accept_timeout_scheduled_seconds":    "1800",
	"booking.start_code_max_attempts":             "5",
	"booking.start_code_lockout_seconds":          "600",
	"search.default_radius_m":                     "5000",
	"quality.rating_floor":                        "3.5",
	"quality.rating_min_jobs":                     "10",
	"quality.max_provider_cancellations_30d":      "3",
	"verification.police_clearance_validity_days": "365",
	"verification.level2_cooling_off_days":        "14",
	"documents.retention_days":                    "365",
}

type reader map[string]string

func (r reader) int(key string) int {
	if n, err := strconv.Atoi(r[key]); err == nil {
		return n
	}
	n, _ := strconv.Atoi(defaults[key])
	return n
}

func (r reader) float(key string) float64 {
	if f, err := strconv.ParseFloat(r[key], 64); err == nil {
		return f
	}
	f, _ := strconv.ParseFloat(defaults[key], 64)
	return f
}

func (r reader) seconds(key string) time.Duration { return time.Duration(r.int(key)) * time.Second }

func (r reader) days(key string) time.Duration { return time.Duration(r.int(key)) * 24 * time.Hour }

// GetSettings implements contract.AdminService.
func (s *Service) GetSettings(ctx context.Context) (contract.Settings, error) {
	values, err := s.svc.Values(ctx)
	if err != nil {
		return contract.Settings{}, err
	}
	r := reader(values)
	return contract.Settings{
		AcceptTimeoutASAP:           r.seconds("booking.accept_timeout_asap_seconds"),
		AcceptTimeoutScheduled:      r.seconds("booking.accept_timeout_scheduled_seconds"),
		DefaultSearchRadiusM:        r.int("search.default_radius_m"),
		RatingFloor:                 r.float("quality.rating_floor"),
		RatingMinJobs:               r.int("quality.rating_min_jobs"),
		MaxProviderCancellations30d: r.int("quality.max_provider_cancellations_30d"),
		StartCodeMaxAttempts:        r.int("booking.start_code_max_attempts"),
		StartCodeLockout:            r.seconds("booking.start_code_lockout_seconds"),
		PoliceClearanceValidity:     r.days("verification.police_clearance_validity_days"),
		Level2CoolingOff:            r.days("verification.level2_cooling_off_days"),
		DocumentRetention:           r.days("documents.retention_days"),
		ServiceAreaGeoJSON:          r["service_area.geojson"],
	}, nil
}

// CountVerifiedComplaints implements contract.AdminService.
func (s *Service) CountVerifiedComplaints(ctx context.Context, againstID uuid.UUID) (int, error) {
	return s.svc.CountVerifiedComplaints(ctx, againstID)
}
