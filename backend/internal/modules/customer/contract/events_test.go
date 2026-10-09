package contract

import "testing"

func TestEventNames(t *testing.T) {
	if got := (CustomerProfileSaved{}).EventName(); got != "customer.CustomerProfileSaved" {
		t.Errorf("EventName() = %q", got)
	}
}
