package domain

import (
	"testing"
	"time"
)

func TestFillDays(t *testing.T) {
	today := time.Date(2026, 10, 9, 0, 0, 0, 0, time.UTC)
	days, rate := FillDays(today, nil)
	if len(days) != DashboardDays || rate != 0 || !days[29].Date.Equal(today) || !days[0].Date.Equal(today.AddDate(0, 0, -29)) {
		t.Fatalf("empty: %v %v", days, rate)
	}
	days, rate = FillDays(today, []DayCount{{Date: today, Total: 2, Completed: 1}, {Date: today.AddDate(0, 0, -3), Total: 1, Completed: 1}})
	if days[29].Total != 2 || days[26].Completed != 1 || rate != 0.67 {
		t.Fatalf("filled: %v %v", days[26:], rate)
	}
}
