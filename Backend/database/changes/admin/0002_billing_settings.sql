-- +goose Up
-- Merchant dues (ADR-0035 §2, §3); admins edit both from the settings screen (A-10).
INSERT INTO admin.settings (key, value, type, description) VALUES
    ('billing.commission_rate_bp', '1000', 'integer', 'PAO commission on a completed job, in basis points of the final price (ADR-0035).'),
    ('billing.due_block_amount', '50000', 'integer', 'Due in paisa above which a merchant cannot accept new jobs (ADR-0035).')
ON CONFLICT (key) DO NOTHING;

-- +goose Down
DELETE FROM admin.settings WHERE key IN ('billing.commission_rate_bp', 'billing.due_block_amount');
