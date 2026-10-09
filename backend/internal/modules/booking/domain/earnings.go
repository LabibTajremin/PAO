package domain

import "time"

// Period returns the first and last calendar day (inclusive) of the day, week or month
// containing day. Weeks start on Saturday, the first working day after the Bangladeshi
// Friday weekend. day must already be a date in Asia/Dhaka.
func Period(period string, day time.Time) (from, to time.Time, err error) {
	d := time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, day.Location())
	switch period {
	case "day":
		return d, d, nil
	case "week":
		from = d.AddDate(0, 0, -((int(d.Weekday()) + 1) % 7))
		return from, from.AddDate(0, 0, 6), nil
	case "month":
		from = time.Date(d.Year(), d.Month(), 1, 0, 0, 0, 0, d.Location())
		return from, from.AddDate(0, 1, -1), nil
	}
	return time.Time{}, time.Time{}, ErrInvalid
}

// Days lists every date from from to to inclusive.
func Days(from, to time.Time) []time.Time {
	var out []time.Time
	for d := from; !d.After(to); d = d.AddDate(0, 0, 1) {
		out = append(out, d)
	}
	return out
}
