-- +goose Up
-- The admin person view (AdminConsole) counts every complaint against a person
-- (ComplaintRepository.CountAgainst) and lists the newest ones they reported or received
-- (Involving). complaints_against_idx covers verified complaints only, so both scanned
-- the whole table.
CREATE INDEX complaints_against_all_idx ON admin.complaints (against_id, created_at DESC, id DESC);

-- +goose Down
DROP INDEX admin.complaints_against_all_idx;
