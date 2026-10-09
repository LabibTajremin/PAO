package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/LabibTajremin/PAO/backend/internal/modules/admin/domain"
	audit "github.com/LabibTajremin/PAO/backend/internal/modules/audit/contract"
	booking "github.com/LabibTajremin/PAO/backend/internal/modules/booking/contract"
	customer "github.com/LabibTajremin/PAO/backend/internal/modules/customer/contract"
	rating "github.com/LabibTajremin/PAO/backend/internal/modules/rating/contract"
)

// CustomerDetail is the admin customer record (A-05).
type CustomerDetail struct {
	Record     customer.CustomerRecord
	Rating     rating.Summary
	Recent     []booking.Summary
	Complaints []domain.Complaint
	History    []audit.Entry
}

// Customers lists customers for the admin console.
func (s *Service) Customers(ctx context.Context, q customer.CustomerQuery) ([]customer.CustomerRecord, error) {
	return s.d.Console.Customers.SearchCustomers(ctx, q)
}

func (s *Service) customerRecord(ctx context.Context, id uuid.UUID) (customer.CustomerRecord, error) {
	list, err := s.d.Console.Customers.SearchCustomers(ctx, customer.CustomerQuery{ID: &id, Limit: 1})
	if err == nil && len(list) == 0 {
		err = domain.ErrPersonNotFound
	}
	if err != nil {
		return customer.CustomerRecord{}, err
	}
	return list[0], nil
}

// CustomerDetail gathers one customer's record, rating, bookings, complaints and history.
func (s *Service) CustomerDetail(ctx context.Context, id uuid.UUID) (CustomerDetail, error) {
	rec, err := s.customerRecord(ctx, id)
	if err != nil {
		return CustomerDetail{}, err
	}
	c, d := s.d.Console, CustomerDetail{Record: rec}
	d.Rating, err = c.Ratings.GetCustomerRating(ctx, id)
	if err == nil {
		d.Recent, err = c.Bookings.ListRecentBookings(ctx, id, recentSize)
	}
	if err == nil {
		d.Complaints, err = s.d.Repo.ComplaintsInvolving(ctx, id, recentSize)
	}
	if err == nil {
		d.History, err = c.Audit.ListForSubject(ctx, "account", id.String(), historySize)
	}
	return d, err
}

// SetCustomerStatus suspends, bans or reinstates a customer (A-05).
func (s *Service) SetCustomerStatus(ctx context.Context, actor, id uuid.UUID, status, reason string) (CustomerDetail, error) {
	if _, err := s.customerRecord(ctx, id); err != nil {
		return CustomerDetail{}, err
	}
	if err := s.setStatus(ctx, actor, id, status, reason); err != nil {
		return CustomerDetail{}, err
	}
	d, err := s.CustomerDetail(ctx, id)
	d.Record.Status = status
	return d, err
}
