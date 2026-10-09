package app

import (
	"context"
	"strconv"

	"github.com/google/uuid"

	identity "github.com/LabibTajremin/PAO/backend/internal/modules/identity/contract"
	verification "github.com/LabibTajremin/PAO/backend/internal/modules/verification/contract"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// items names verification items in both languages for message text.
var items = map[string][2]string{
	"nid": {"NID", "এনআইডি"}, "selfie": {"selfie", "সেলফি"}, "police_clearance": {"police clearance", "পুলিশ ক্লিয়ারেন্স"},
	"address": {"address", "ঠিকানা"}, "emergency_contact": {"emergency contact", "জরুরি যোগাযোগ"}, "skill_proof": {"skill proof", "দক্ষতার প্রমাণ"},
	"service_area": {"service area", "সেবা এলাকা"}, "code_of_conduct": {"code of conduct", "আচরণবিধি"},
}

func itemName(item, lang string) string {
	if lang == "en" {
		return items[item][0]
	}
	return items[item][1]
}

// toProvider sends a partner-app message about verification.
func (s *Service) toProvider(ctx context.Context, env eventbus.Envelope, id uuid.UUID, template string, data func(lang string) map[string]string) error {
	lang := s.d.Languages.Language(ctx, id, "partner")
	return s.Send(ctx, Message{Recipient: id, App: "partner", Template: template, Data: data(lang), DedupeKey: env.ID.String(), Language: lang})
}

func decoded[T eventbus.Event](fn func(ctx context.Context, env eventbus.Envelope, e T) error) eventbus.Handler {
	return func(ctx context.Context, env eventbus.Envelope) error {
		e, err := eventbus.Decode[T](env)
		if err != nil {
			return err
		}
		return fn(ctx, env, e)
	}
}

// Handlers maps every event that notifies someone to its handler.
func (s *Service) Handlers() map[string]eventbus.Handler {
	out := map[string]eventbus.Handler{
		verification.ProviderLevelChanged{}.EventName(): decoded(func(ctx context.Context, env eventbus.Envelope, e verification.ProviderLevelChanged) error {
			return s.toProvider(ctx, env, e.ProviderID, "level_changed", func(string) map[string]string { return map[string]string{"level": strconv.Itoa(e.To)} })
		}),
		verification.DocumentRejected{}.EventName(): decoded(func(ctx context.Context, env eventbus.Envelope, e verification.DocumentRejected) error {
			return s.toProvider(ctx, env, e.ProviderID, "document_rejected", func(l string) map[string]string {
				return map[string]string{"item": itemName(string(e.Item), l), "reason": e.Reason}
			})
		}),
		verification.DocumentExpired{}.EventName(): decoded(func(ctx context.Context, env eventbus.Envelope, e verification.DocumentExpired) error {
			return s.toProvider(ctx, env, e.ProviderID, "document_expired", func(l string) map[string]string { return map[string]string{"item": itemName(string(e.Item), l)} })
		}),
		verification.DocumentExpiring{}.EventName(): decoded(func(ctx context.Context, env eventbus.Envelope, e verification.DocumentExpiring) error {
			return s.toProvider(ctx, env, e.ProviderID, "document_expiring", func(l string) map[string]string {
				return map[string]string{"item": itemName(string(e.Item), l), "days": strconv.Itoa(e.DaysLeft)}
			})
		}),
		verification.Level2SessionScheduled{}.EventName(): decoded(func(ctx context.Context, env eventbus.Envelope, e verification.Level2SessionScheduled) error {
			return s.toProvider(ctx, env, e.ProviderID, "level2_scheduled", func(string) map[string]string {
				return map[string]string{"location": e.Location, "when": e.ScheduledAt}
			})
		}),
		identity.AccountDeleted{}.EventName(): decoded(func(ctx context.Context, _ eventbus.Envelope, e identity.AccountDeleted) error {
			return s.Forget(ctx, e.AccountID)
		}),
	}
	for name, build := range bookingNotes {
		out[name] = s.onBooking(build)
	}
	return out
}
