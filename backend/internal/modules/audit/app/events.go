package app

import (
	"context"

	"github.com/google/uuid"

	admin "github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/audit/domain"
	catalog "github.com/LabibTajremin/PAO/backend/internal/modules/catalog/contract"
	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Handlers maps event names to the functions that audit them. Every event that changes
// a person's status, a price or a decision is audited (02-architecture §8).
func (s *Service) Handlers() map[string]eventbus.Handler {
	hs := map[string]eventbus.Handler{
		identity.AccountStatusChanged{}.EventName(): s.onAccountStatusChanged,
		catalog.PriceChanged{}.EventName():          s.onPriceChanged,
		admin.SettingChanged{}.EventName():          s.onSettingChanged,
	}
	for name, h := range s.verificationHandlers() {
		hs[name] = h
	}
	return hs
}

func (s *Service) fromEvent(ctx context.Context, env eventbus.Envelope, e domain.Entry) error {
	id := env.ID
	e.EventID, e.At = &id, env.OccurredAt
	return s.Record(ctx, e)
}

func actor(id uuid.UUID) *uuid.UUID {
	if id == uuid.Nil {
		return nil
	}
	return &id
}

func (s *Service) onAccountStatusChanged(ctx context.Context, env eventbus.Envelope) error {
	e, err := eventbus.Decode[identity.AccountStatusChanged](env)
	if err != nil {
		return err
	}
	return s.fromEvent(ctx, env, domain.Entry{
		ActorID: actor(e.ActorID), Action: "account.status_changed", SubjectType: "account", SubjectID: e.AccountID.String(),
		Reason: e.Reason, Before: map[string]any{"status": e.From}, After: map[string]any{"status": e.To},
	})
}

func (s *Service) onPriceChanged(ctx context.Context, env eventbus.Envelope) error {
	e, err := eventbus.Decode[catalog.PriceChanged](env)
	if err != nil {
		return err
	}
	return s.fromEvent(ctx, env, domain.Entry{
		ActorID: actor(e.ActorID), Action: "catalog.price_changed", SubjectType: "sub_service", SubjectID: e.SubServiceID.String(),
		After: map[string]any{"amountPaisa": e.AmountPaisa, "priceVersionId": e.PriceVersionID.String()},
	})
}

func (s *Service) onSettingChanged(ctx context.Context, env eventbus.Envelope) error {
	e, err := eventbus.Decode[admin.SettingChanged](env)
	if err != nil {
		return err
	}
	return s.fromEvent(ctx, env, domain.Entry{
		ActorID: actor(e.ActorID), Action: "settings.changed", SubjectType: "setting", SubjectID: e.Key,
		Before: map[string]any{"value": e.Before}, After: map[string]any{"value": e.After},
	})
}
