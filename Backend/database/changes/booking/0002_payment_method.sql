-- +goose Up
-- Cash on delivery is the only payment method of the first release (ADR-0035 §1).
ALTER TABLE booking.bookings
    ADD COLUMN payment_method text NOT NULL DEFAULT 'cash_on_delivery' CHECK (payment_method IN ('cash_on_delivery'));

-- +goose Down
ALTER TABLE booking.bookings DROP COLUMN payment_method;
