-- +goose Up
-- Merchant payment review (ADR-0035 §4): super admins and support agents, who already
-- work with providers, confirm or reject payments.
INSERT INTO identity.permissions (name, description) VALUES
    ('billing:manage', 'Review merchant payments and ledgers');

INSERT INTO identity.role_permissions (role, permission) VALUES
    ('support_agent', 'billing:manage'),
    ('super_admin', 'billing:manage');

-- +goose Down
DELETE FROM identity.role_permissions WHERE permission = 'billing:manage';
DELETE FROM identity.permissions WHERE name = 'billing:manage';
