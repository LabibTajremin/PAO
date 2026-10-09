// Package inproc implements the audit contract for other modules in the process.
package inproc

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/app"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/port"
)

// Service adapts the audit use cases to contract.AuditService.
type Service struct{ svc *app.Service }

// New returns the in-process contract implementation.
func New(svc *app.Service) *Service { return &Service{svc: svc} }

var _ contract.AuditService = (*Service)(nil)

// Record implements contract.AuditService.
func (s *Service) Record(ctx context.Context, e contract.Entry) error {
	return s.svc.Record(ctx, domain.Entry{At: e.At, ActorID: e.ActorID, ActorRole: e.ActorRole, Action: e.Action,
		SubjectType: e.SubjectType, SubjectID: e.SubjectID, Reason: e.Reason, Before: e.Before, After: e.After})
}

// ListForSubject implements contract.AuditService.
func (s *Service) ListForSubject(ctx context.Context, subjectType, subjectID string, limit int) ([]contract.Entry, error) {
	entries, err := s.svc.List(ctx, domain.Filter{SubjectType: subjectType, SubjectID: subjectID}, port.Page{Limit: limit})
	out := make([]contract.Entry, 0, len(entries))
	for _, e := range entries {
		out = append(out, contract.Entry{ID: e.ID, At: e.At, ActorID: e.ActorID, ActorRole: e.ActorRole, Action: e.Action,
			SubjectType: e.SubjectType, SubjectID: e.SubjectID, Reason: e.Reason, Before: e.Before, After: e.After})
	}
	return out, err
}
