package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/contract"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/port"
	"github.com/LabibTajremin/PAO/backend/internal/platform/eventbus"
)

// Report files a complaint by one party of a booking against the other (C-14). A
// stranger to the booking gets ErrBookingNotFound so booking IDs cannot be probed.
func (s *Service) Report(ctx context.Context, in domain.Complaint) (domain.Complaint, error) {
	if err := in.Validate(); err != nil {
		return domain.Complaint{}, err
	}
	customer, provider, err := s.d.Bookings.Parties(ctx, in.BookingID)
	if err != nil {
		return domain.Complaint{}, err
	}
	sides := map[string][2]uuid.UUID{"customer": {customer, provider}, "provider": {provider, customer}}[in.ReporterRole]
	if sides[0] != in.ReporterID {
		return domain.Complaint{}, domain.ErrBookingNotFound
	}
	if err := s.d.Media.AttachComplaintPhotos(ctx, in.ReporterID, in.Photos); err != nil {
		return domain.Complaint{}, err
	}
	now := s.d.Clock.Now()
	in.ID, in.AgainstID, in.Status, in.CreatedAt, in.UpdatedAt = s.d.IDs.New(), sides[1], domain.StatusOpen, now, now
	return s.d.Repo.CreateComplaint(ctx, in, func(c domain.Complaint) eventbus.Event {
		return contract.ComplaintCreated{ComplaintID: c.ID, TicketNumber: c.TicketNumber(), BookingID: c.BookingID, ReporterID: c.ReporterID,
			ReporterRole: c.ReporterRole, AgainstID: c.AgainstID}
	})
}

// Complaint returns one complaint with its comments.
func (s *Service) Complaint(ctx context.Context, id uuid.UUID) (domain.Complaint, error) {
	return s.d.Repo.GetComplaint(ctx, id)
}

// Complaints returns a page of the queue.
func (s *Service) Complaints(ctx context.Context, f port.ComplaintFilter) ([]domain.Complaint, error) {
	return s.d.Repo.ListComplaints(ctx, f)
}

// Assign hands a complaint to an admin who may work the queue (A-07).
func (s *Service) Assign(ctx context.Context, id, assignee uuid.UUID) (domain.Complaint, error) {
	ok, err := s.d.Admins.CanWorkComplaints(ctx, assignee)
	if err == nil && !ok {
		err = domain.ErrInvalidAssignee
	}
	if err != nil {
		return domain.Complaint{}, err
	}
	return s.d.Repo.SaveComplaint(ctx, id, func(c *domain.Complaint) (eventbus.Event, error) {
		return nil, c.Assign(assignee, s.d.Clock.Now())
	})
}

// Comment adds an internal note and returns the complaint with every note.
func (s *Service) Comment(ctx context.Context, id, author uuid.UUID, body string) (domain.Complaint, error) {
	_, err := s.d.Repo.GetComplaint(ctx, id)
	if err == nil {
		err = s.d.Repo.AddComment(ctx, domain.Comment{ID: s.d.IDs.New(), ComplaintID: id, AuthorID: author, Body: body, At: s.d.Clock.Now()})
	}
	if err != nil {
		return domain.Complaint{}, err
	}
	return s.d.Repo.GetComplaint(ctx, id)
}

// Resolve closes a complaint; ComplaintResolved tells the reporter and, when verified,
// feeds the provider quality review (PRD §6.4).
func (s *Service) Resolve(ctx context.Context, id, actor uuid.UUID, note string, verified bool) (domain.Complaint, error) {
	return s.d.Repo.SaveComplaint(ctx, id, func(c *domain.Complaint) (eventbus.Event, error) {
		err := c.Resolve(note, verified, s.d.Clock.Now())
		return contract.ComplaintResolved{ComplaintID: c.ID, TicketNumber: c.TicketNumber(), BookingID: c.BookingID, ReporterID: c.ReporterID,
			ReporterRole: c.ReporterRole, AgainstID: c.AgainstID, Verified: verified, ActorID: actor}, err
	})
}
