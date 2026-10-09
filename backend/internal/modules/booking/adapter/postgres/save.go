package postgres

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/adapter/postgres/sqlcdb"
	"github.com/LabibTajremin/PAO/backend/internal/modules/booking/domain"
)

func insertLine(ctx context.Context, q *sqlcdb.Queries, booking uuid.UUID, l domain.Line) error {
	return q.InsertItem(ctx, sqlcdb.InsertItemParams{ID: l.ID, BookingID: booking, ProposalID: l.ProposalID, SubServiceID: l.SubServiceID,
		PriceVersionID: l.PriceVersionID, NameEn: l.Name.EN, NameBn: l.Name.BN, Unit: l.Unit, Quantity: int32(l.Quantity), //nolint:gosec // ≤ 50
		UnitPricePaisa: l.UnitPaisa, TotalPaisa: l.TotalPaisa, Extra: l.Extra, Position: int32(l.Position)}) //nolint:gosec // ≤ 110 lines
}

// save writes lines, proposals and new timeline entries; lines are immutable, so
// re-inserting known ones is a no-op.
func save(ctx context.Context, q *sqlcdb.Queries, b domain.Booking) error {
	var err error
	for _, p := range b.Proposals {
		if err == nil {
			err = q.UpsertProposal(ctx, sqlcdb.UpsertProposalParams{ID: p.ID, BookingID: b.ID, Status: p.Status, AddedPaisa: p.AddedPaisa,
				ProposedAt: p.ProposedAt, DecidedAt: p.DecidedAt})
		}
		for _, l := range p.Lines {
			if err == nil {
				err = insertLine(ctx, q, b.ID, l)
			}
		}
	}
	for _, l := range b.Lines {
		if err == nil {
			err = insertLine(ctx, q, b.ID, l)
		}
	}
	for _, e := range b.NewEvents {
		if err == nil {
			err = q.InsertTimeline(ctx, sqlcdb.InsertTimelineParams{ID: e.ID, BookingID: b.ID, Status: e.Status, Actor: e.Actor, Reason: e.Reason, At: e.At})
		}
	}
	return err
}

func update(ctx context.Context, q *sqlcdb.Queries, b domain.Booking, now time.Time) error {
	var cancelledBy *string
	if b.CancelledBy != "" {
		cancelledBy = &b.CancelledBy
	}
	err := q.UpdateBooking(ctx, sqlcdb.UpdateBookingParams{ID: b.ID, Status: b.Status, TotalPaisa: b.TotalPaisa,
		StartCodeAttempts: int32(b.CodeAttempts), StartCodeLockedUntil: b.CodeLockedUntil, CashReceived: b.CashReceived, //nolint:gosec // ≤ 5
		CancelReason: b.CancelReason, CancelledBy: cancelledBy, RejectReason: b.RejectReason, AcceptedAt: b.AcceptedAt,
		StartedAt: b.StartedAt, CompletedAt: b.CompletedAt, CancelledAt: b.CancelledAt, UpdatedAt: now, StartCode: b.StartCode})
	if err == nil {
		err = save(ctx, q, b)
	}
	return err
}
