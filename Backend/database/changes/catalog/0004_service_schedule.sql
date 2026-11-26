-- +goose Up
-- Scheduled delivery (ADR-0041): a fifth service model whose services carry the ordering
-- rules the admin sets (patterns, windows, lead time, cutoff, unit, quantity range).
ALTER TABLE catalog.services DROP CONSTRAINT services_service_model_check;
ALTER TABLE catalog.services ADD CONSTRAINT services_service_model_check
    CHECK (service_model IN ('on_demand', 'duration_hire', 'listing', 'partner_referral', 'scheduled_delivery'));
ALTER TABLE catalog.services ADD COLUMN schedule jsonb;
ALTER TABLE catalog.services ADD CONSTRAINT services_schedule_model_check
    CHECK ((service_model = 'scheduled_delivery') = (schedule IS NOT NULL));

-- +goose Down
ALTER TABLE catalog.services DROP CONSTRAINT services_schedule_model_check;
ALTER TABLE catalog.services DROP COLUMN schedule;
ALTER TABLE catalog.services DROP CONSTRAINT services_service_model_check;
ALTER TABLE catalog.services ADD CONSTRAINT services_service_model_check
    CHECK (service_model IN ('on_demand', 'duration_hire', 'listing', 'partner_referral'));
