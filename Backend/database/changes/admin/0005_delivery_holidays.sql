-- +goose Up
-- Dates without scheduled deliveries (ADR-0041 §3), such as Eid days; empty by default.
INSERT INTO admin.settings (key, value, type, description) VALUES
    ('booking.delivery_holidays', '', 'string', 'Dates without scheduled deliveries, as comma-separated YYYY-MM-DD');

-- +goose Down
DELETE FROM admin.settings WHERE key = 'booking.delivery_holidays';
