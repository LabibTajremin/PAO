package domain

import (
	"time"

	"github.com/google/uuid"
)

// move applies a transition from the table and records it on the timeline.
func (b *Booking) move(to, actor, reason string, now time.Time, id uuid.UUID) error {
	if !CanTransition(b.Status, to, actor) {
		return ErrInvalidTransition
	}
	b.Status = to
	e := Event{ID: id, Status: to, Actor: actor, Reason: reason, At: now}
	b.Timeline, b.NewEvents = append(b.Timeline, e), append(b.NewEvents, e)
	return nil
}

// Accept is transition 1: before the deadline, and for an ASAP booking only when the
// provider has no other active job (PRD §5).
func (b *Booking) Accept(now time.Time, id uuid.UUID) error {
	if b.Status == Requested && !now.Before(b.AcceptDeadline) {
		return ErrDeadlinePassed
	}
	if b.Status == Requested && !b.Scheduled && b.ProviderActiveJobs > 0 {
		return ErrActiveJob
	}
	if err := b.move(Accepted, ByProvider, "", now, id); err != nil {
		return err
	}
	b.AcceptedAt = &now
	return nil
}

// Reject is transition 2.
func (b *Booking) Reject(now time.Time, id uuid.UUID, reason string) error {
	if b.Status == Requested && !now.Before(b.AcceptDeadline) {
		return ErrDeadlinePassed
	}
	if err := b.move(Rejected, ByProvider, reason, now, id); err != nil {
		return err
	}
	b.RejectReason = reason
	return nil
}

// TimeOut is transition 3, applied by the expiry job once the deadline passed.
func (b *Booking) TimeOut(now time.Time, id uuid.UUID) error {
	if now.Before(b.AcceptDeadline) {
		return ErrInvalidTransition
	}
	return b.move(TimedOut, BySystem, "", now, id)
}

// Cancel is transitions 4, 9 and 10; nobody may cancel once the job started (D8).
func (b *Booking) Cancel(now time.Time, id uuid.UUID, actor, reason string) error {
	if b.Status == InProgress || b.Status == Completed {
		return ErrCancelNotAllowed
	}
	if err := b.move(Cancelled, actor, reason, now, id); err != nil {
		return err
	}
	b.CancelReason, b.CancelledBy, b.CancelledAt = reason, actor, &now
	return nil
}

// AfterAcceptance reports whether a cancellation happened after the provider accepted.
func (b *Booking) AfterAcceptance() bool { return b.AcceptedAt != nil }

// Advance is transitions 5 and 6.
func (b *Booking) Advance(to string, now time.Time, id uuid.UUID) error {
	if to != OnTheWay && to != Arrived {
		return ErrInvalidTransition
	}
	return b.move(to, ByProvider, "", now, id)
}

// Start is transition 7. A wrong code counts an attempt; the last allowed wrong
// attempt locks entry for the lockout period. The booking changes even when an error
// is returned, so callers save it either way.
func (b *Booking) Start(code string, now time.Time, id uuid.UUID, maxAttempts int, lockout time.Duration) error {
	if b.Status != Arrived {
		return ErrInvalidTransition
	}
	if b.CodeLockedUntil != nil && now.Before(*b.CodeLockedUntil) {
		return ErrCodeLocked
	}
	if code != b.StartCode {
		b.CodeAttempts++
		if b.CodeAttempts >= maxAttempts {
			until := now.Add(lockout)
			b.CodeAttempts, b.CodeLockedUntil = 0, &until
		}
		return ErrCodeWrong
	}
	b.CodeAttempts, b.CodeLockedUntil, b.StartedAt = 0, nil, &now
	return b.move(InProgress, ByProvider, "", now, id)
}

// Propose adds an extras proposal of catalog items (PRD §5: no free-text prices).
func (b *Booking) Propose(p Proposal) error {
	if b.Status != InProgress {
		return ErrInvalidTransition
	}
	if b.Pending() != nil {
		return ErrExtrasPending
	}
	if len(p.Lines) == 0 {
		return ErrInvalid
	}
	p.Status, p.AddedPaisa = "pending", Total(p.Lines)
	b.Proposals = append(b.Proposals, p)
	return nil
}

// Decide approves or declines the pending proposal; approved items join the bill.
func (b *Booking) Decide(proposalID uuid.UUID, approve bool, now time.Time) (*Proposal, error) {
	p := b.Pending()
	if b.Status != InProgress || p == nil || p.ID != proposalID {
		return nil, ErrNoProposal
	}
	p.Status, p.DecidedAt = "declined", &now
	if !approve {
		return p, nil
	}
	p.Status = "approved"
	for _, l := range p.Lines {
		l.Extra, l.ProposalID = true, &p.ID
		b.Lines = append(b.Lines, l)
	}
	b.TotalPaisa = Total(b.Lines)
	return p, nil
}

// Complete is transition 8: cash confirmed and no proposal pending (D4).
func (b *Booking) Complete(cash bool, now time.Time, id uuid.UUID) error {
	if b.Status == InProgress && !cash {
		return ErrCashNotConfirmed
	}
	if b.Status == InProgress && b.Pending() != nil {
		return ErrExtrasPending
	}
	if err := b.move(Completed, ByProvider, "", now, id); err != nil {
		return err
	}
	b.CashReceived, b.CompletedAt = true, &now
	return nil
}
