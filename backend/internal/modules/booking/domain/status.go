// Package domain holds the booking state machine, totals and earnings periods
// (PRD §5, docs/booking-states.md).
package domain

import (
	"errors"
	"slices"
)

// Booking errors.
var (
	ErrNotFound          = errors.New("booking not found")
	ErrInvalid           = errors.New("booking details are not valid")
	ErrInvalidTransition = errors.New("booking cannot move to that state")
	ErrDeadlinePassed    = errors.New("the time to answer has passed")
	ErrActiveJob         = errors.New("provider already has an active job")
	ErrCodeWrong         = errors.New("start code is wrong")
	ErrCodeLocked        = errors.New("start code entry is locked")
	ErrCashNotConfirmed  = errors.New("cash received must be confirmed")
	ErrExtrasPending     = errors.New("an extras proposal is waiting for the customer")
	ErrNoProposal        = errors.New("no extras proposal is waiting")
	ErrNotBookable       = errors.New("provider or service cannot take this booking")
	ErrDuplicateRequest  = errors.New("an open request to this provider already exists")
	ErrCancelNotAllowed  = errors.New("cancellation is not allowed after the job started")
	ErrOutsideArea       = errors.New("this address is outside the service area")
	ErrProfileRequired   = errors.New("customer profile must exist before booking")
)

// Booking states.
const (
	Requested  = "requested"
	Accepted   = "accepted"
	OnTheWay   = "on_the_way"
	Arrived    = "arrived"
	InProgress = "in_progress"
	Completed  = "completed"
	Rejected   = "rejected"
	TimedOut   = "timed_out"
	Cancelled  = "cancelled"
)

// Actors who move a booking.
const (
	ByCustomer = "customer"
	ByProvider = "provider"
	BySystem   = "system"
)

// transitions is the table in docs/booking-states.md: from → to → allowed actors.
var transitions = map[string]map[string][]string{
	Requested:  {Accepted: {ByProvider}, Rejected: {ByProvider}, TimedOut: {BySystem}, Cancelled: {ByCustomer}},
	Accepted:   {OnTheWay: {ByProvider}, Cancelled: {ByCustomer, ByProvider}},
	OnTheWay:   {Arrived: {ByProvider}, Cancelled: {ByCustomer, ByProvider}},
	Arrived:    {InProgress: {ByProvider}, Cancelled: {ByCustomer, ByProvider}},
	InProgress: {Completed: {ByProvider}},
}

// CanTransition reports whether actor may move a booking from one state to another.
func CanTransition(from, to, actor string) bool {
	return slices.Contains(transitions[from][to], actor)
}

// Active states hold the provider: they count against the one-active-job rule.
var Active = []string{Accepted, OnTheWay, Arrived, InProgress}

// Upcoming states are shown on the upcoming tab; the rest are past.
var Upcoming = []string{Requested, Accepted, OnTheWay, Arrived, InProgress}
