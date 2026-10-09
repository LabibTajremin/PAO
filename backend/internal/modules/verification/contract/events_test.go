package contract

import (
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

func TestEventNames(t *testing.T) {
	events := map[string]eventbus.Event{
		"verification.ProviderLevelChanged":   ProviderLevelChanged{},
		"verification.DocumentApproved":       DocumentApproved{},
		"verification.DocumentRejected":       DocumentRejected{},
		"verification.DocumentExpired":        DocumentExpired{},
		"verification.DocumentExpiring":       DocumentExpiring{},
		"verification.Level2SessionScheduled": Level2SessionScheduled{},
	}
	for want, e := range events {
		if got := e.EventName(); got != want {
			t.Errorf("EventName() = %q, want %q", got, want)
		}
	}
}
