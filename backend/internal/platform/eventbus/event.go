// Package eventbus defines domain events and the in-process bus modules publish them
// on (PRD §9.3 rule 5).
package eventbus

// Event is a domain event. Its name is stable across releases because it is stored in
// the outbox and may later travel over a message broker.
type Event interface {
	EventName() string
}
