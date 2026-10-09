package contract

import "testing"

func TestEventNames(t *testing.T) {
	if got := (ReviewSubmitted{}).EventName(); got != "rating.ReviewSubmitted" {
		t.Errorf("EventName() = %q", got)
	}
}
