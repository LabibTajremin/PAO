package domain

import (
	"math"
	"time"
)

// DashboardDays is how many days of bookings the dashboard charts (A-09).
const DashboardDays = 30

// DayCount is one day's bookings.
type DayCount struct {
	Date      time.Time
	Total     int
	Completed int
}

// Dashboard is the admin home screen's numbers (A-09).
type Dashboard struct {
	ProvidersByStatus    map[string]int
	ProvidersByLevel     map[string]int
	BookingsPerDay       []DayCount
	CompletionRate       float64
	OpenComplaints       int
	PendingVerifications int
	GeneratedAt          time.Time
}

// FillDays returns one entry per day of the window ending today, so charts show gaps
// as zeros, and the share of requested bookings that were completed.
func FillDays(today time.Time, stored []DayCount) ([]DayCount, float64) {
	byDay := map[string]DayCount{}
	for _, d := range stored {
		byDay[d.Date.Format(time.DateOnly)] = d
	}
	out := make([]DayCount, 0, DashboardDays)
	total, completed := 0, 0
	for i := DashboardDays - 1; i >= 0; i-- {
		day := today.AddDate(0, 0, -i)
		d := byDay[day.Format(time.DateOnly)]
		d.Date = day
		total, completed = total+d.Total, completed+d.Completed
		out = append(out, d)
	}
	if total == 0 {
		return out, 0
	}
	return out, math.Round(float64(completed)/float64(total)*100) / 100
}
