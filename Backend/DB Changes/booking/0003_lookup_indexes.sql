-- +goose Up
-- The expiry sweep (BookingExpiryJob, every 15 s) takes requests whose accept deadline
-- passed, oldest first (BookingQueries.Due): a small partial index ordered by deadline.
CREATE INDEX bookings_accept_due_idx ON booking.bookings (accept_deadline) WHERE status = 'requested';

-- The admin booking monitor (A-06, BookingQueries.Monitor) pages every booking newest
-- first, (created_at, id) keyset, often without a status filter.
CREATE INDEX bookings_created_idx ON booking.bookings (created_at DESC, id DESC);

-- Every booking read (BookingQueries.Get) and state change (BookingRepository.Change)
-- reads its extras proposals by booking; only the pending one was indexed.
CREATE INDEX extras_proposals_booking_idx ON booking.extras_proposals (booking_id, proposed_at);

-- +goose Down
DROP INDEX booking.extras_proposals_booking_idx;
DROP INDEX booking.bookings_created_idx;
DROP INDEX booking.bookings_accept_due_idx;
