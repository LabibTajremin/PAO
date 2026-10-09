package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
)

func toBooking(r sqlcdb.BookingByIDRow) domain.Booking {
	b := domain.Booking{ID: r.ID, Number: r.Number, ServiceID: r.ServiceID, ServiceName: domain.Text{EN: r.ServiceNameEn, BN: r.ServiceNameBn},
		ServiceModel: r.ServiceModel, Customer: domain.Party{ID: r.CustomerID, Name: r.CustomerName, Phone: r.CustomerPhone},
		Provider: domain.Party{ID: r.ProviderID, Name: r.ProviderName, Phone: r.ProviderPhone},
		Address:  domain.Address{ID: r.AddressID, Area: r.AddressArea, Line1: r.AddressLine1, Line2: r.AddressLine2, Location: domain.Point{Lat: r.Lat, Lng: r.Lng}},
		Note:     r.Note, Status: r.Status, Scheduled: r.Timing == "scheduled", ScheduledAt: r.ScheduledAt, EndsAt: r.EndsAt,
		AcceptDeadline: r.AcceptDeadline, TotalPaisa: r.TotalPaisa, StartCode: r.StartCode, CodeAttempts: int(r.StartCodeAttempts),
		CodeLockedUntil: r.StartCodeLockedUntil, CashReceived: r.CashReceived, IdempotencyKey: r.IdempotencyKey, CancelReason: r.CancelReason,
		RejectReason: r.RejectReason, CreatedAt: r.CreatedAt, AcceptedAt: r.AcceptedAt, StartedAt: r.StartedAt, CompletedAt: r.CompletedAt,
		CancelledAt: r.CancelledAt}
	if r.CancelledBy != nil {
		b.CancelledBy = *r.CancelledBy
	}
	return b
}

func toLine(r sqlcdb.ItemsByBookingRow) domain.Line {
	return domain.Line{ID: r.ID, SubServiceID: r.SubServiceID, PriceVersionID: r.PriceVersionID, Name: domain.Text{EN: r.NameEn, BN: r.NameBn},
		Unit: r.Unit, Quantity: int(r.Quantity), UnitPaisa: r.UnitPricePaisa, TotalPaisa: r.TotalPaisa, Extra: r.Extra, ProposalID: r.ProposalID,
		Position: int(r.Position)}
}

// load reads a booking with its lines, proposals and timeline. Lines of an approved
// proposal are part of the bill; lines of other proposals stay with the proposal.
func load(ctx context.Context, q *sqlcdb.Queries, id uuid.UUID) (domain.Booking, error) {
	row, err := q.BookingByID(ctx, id)
	if errors.Is(err, pgx.ErrNoRows) {
		err = domain.ErrNotFound
	}
	if err != nil {
		return domain.Booking{}, err
	}
	b := toBooking(row)
	props, err := q.ProposalsByBooking(ctx, id)
	index := map[uuid.UUID]int{}
	for i, p := range props {
		index[p.ID] = i
		b.Proposals = append(b.Proposals, domain.Proposal{ID: p.ID, Status: p.Status, AddedPaisa: p.AddedPaisa, ProposedAt: p.ProposedAt, DecidedAt: p.DecidedAt})
	}
	var items []sqlcdb.ItemsByBookingRow
	if err == nil {
		items, err = q.ItemsByBooking(ctx, id)
	}
	for _, it := range items {
		l := toLine(it)
		if l.ProposalID == nil {
			b.Lines = append(b.Lines, l)
			continue
		}
		p := &b.Proposals[index[*l.ProposalID]]
		p.Lines = append(p.Lines, l)
		if p.Status == "approved" {
			b.Lines = append(b.Lines, l)
		}
	}
	var events []sqlcdb.TimelineByBookingRow
	if err == nil {
		events, err = q.TimelineByBooking(ctx, id)
	}
	for _, e := range events {
		b.Timeline = append(b.Timeline, domain.Event{ID: e.ID, Status: e.Status, Actor: e.Actor, Reason: e.Reason, At: e.At})
	}
	return b, err
}
