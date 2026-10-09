package contract

import (
	"testing"

	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

func TestEventNames(t *testing.T) {
	events := map[string]eventbus.Event{
		"identity.AccountCreated":       AccountCreated{},
		"identity.RoleGranted":          RoleGranted{},
		"identity.AccountStatusChanged": AccountStatusChanged{},
		"identity.AccountDeleted":       AccountDeleted{},
	}
	for want, e := range events {
		if got := e.EventName(); got != want {
			t.Errorf("EventName() = %q, want %q", got, want)
		}
	}
}
