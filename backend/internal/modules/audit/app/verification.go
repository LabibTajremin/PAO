package app

import (
	"context"

	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/domain"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// verificationHandlers audit every verification decision: who, when, what and why
// (PRD §6.4).
func (s *Service) verificationHandlers() map[string]eventbus.Handler {
	return map[string]eventbus.Handler{
		verification.DocumentApproved{}.EventName():     s.onDocumentApproved,
		verification.DocumentRejected{}.EventName():     s.onDocumentRejected,
		verification.ProviderLevelChanged{}.EventName(): s.onLevelChanged,
		verification.Level2ResultRecorded{}.EventName(): s.onLevel2Result,
		verification.DocumentExpired{}.EventName():      s.onDocumentExpired,
	}
}

func (s *Service) onDocumentApproved(ctx context.Context, env eventbus.Envelope) error {
	e, err := eventbus.Decode[verification.DocumentApproved](env)
	if err != nil {
		return err
	}
	return s.fromEvent(ctx, env, domain.Entry{ActorID: actor(e.ActorID), ActorRole: "verifier", Action: "verification.item_approved",
		SubjectType: "provider", SubjectID: e.ProviderID.String(), After: map[string]any{"item": e.Item, "status": "approved"}})
}

func (s *Service) onDocumentRejected(ctx context.Context, env eventbus.Envelope) error {
	e, err := eventbus.Decode[verification.DocumentRejected](env)
	if err != nil {
		return err
	}
	return s.fromEvent(ctx, env, domain.Entry{ActorID: actor(e.ActorID), ActorRole: "verifier", Action: "verification.item_rejected",
		SubjectType: "provider", SubjectID: e.ProviderID.String(), Reason: e.Reason, After: map[string]any{"item": e.Item, "status": "rejected"}})
}

func (s *Service) onLevelChanged(ctx context.Context, env eventbus.Envelope) error {
	e, err := eventbus.Decode[verification.ProviderLevelChanged](env)
	if err != nil {
		return err
	}
	return s.fromEvent(ctx, env, domain.Entry{Action: "verification.level_changed", SubjectType: "provider", SubjectID: e.ProviderID.String(),
		Reason: e.Reason, Before: map[string]any{"level": e.From}, After: map[string]any{"level": e.To}})
}

func (s *Service) onLevel2Result(ctx context.Context, env eventbus.Envelope) error {
	e, err := eventbus.Decode[verification.Level2ResultRecorded](env)
	if err != nil {
		return err
	}
	return s.fromEvent(ctx, env, domain.Entry{ActorID: actor(e.ActorID), ActorRole: "verifier", Action: "verification.level2_result",
		SubjectType: "provider", SubjectID: e.ProviderID.String(), After: map[string]any{"session": e.SessionID.String(), "result": e.Result}})
}

func (s *Service) onDocumentExpired(ctx context.Context, env eventbus.Envelope) error {
	e, err := eventbus.Decode[verification.DocumentExpired](env)
	if err != nil {
		return err
	}
	return s.fromEvent(ctx, env, domain.Entry{Action: "verification.item_expired", SubjectType: "provider", SubjectID: e.ProviderID.String(),
		After: map[string]any{"item": e.Item, "status": "expired"}})
}
