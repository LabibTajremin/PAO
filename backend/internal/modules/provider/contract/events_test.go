package contract

import (
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

func TestEventNames(t *testing.T) {
	events := map[string]eventbus.Event{
		"provider.EnrolmentStepSaved":       EnrolmentStepSaved{},
		"provider.ProviderFlaggedForReview": ProviderFlaggedForReview{},
		"provider.ProviderWentOffline":      ProviderWentOffline{},
	}
	for want, e := range events {
		if got := e.EventName(); got != want {
			t.Errorf("EventName() = %q, want %q", got, want)
		}
	}
}
