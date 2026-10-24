-- Prints one "name|value" line per application table (its row count) and per goose
-- version table (the highest applied migration). Two databases with the same output
-- hold the same data as far as a restore drill can tell.
WITH app_tables AS (
  SELECT n.nspname AS schema_name, c.relname AS table_name
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.relkind IN ('r', 'p')
    AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'tiger', 'tiger_data', 'topology')
    AND n.nspname NOT LIKE 'pg\_%'
    AND NOT (n.nspname = 'public' AND c.relname = 'spatial_ref_sys')
),
scalar AS (
  SELECT schema_name || '.' || table_name AS name,
    format('SELECT count(*) AS v FROM %I.%I', schema_name, table_name) AS sql
  FROM app_tables
  UNION ALL
  SELECT 'migration ' || table_name,
    format('SELECT max(version_id) AS v FROM %I.%I WHERE is_applied', schema_name, table_name)
  FROM app_tables
  WHERE schema_name = 'public' AND table_name LIKE 'goose\_%'
)
SELECT name || '|' || coalesce((xpath('/row/v/text()', query_to_xml(sql, false, true, '')))[1]::text, 'none')
FROM scalar
ORDER BY name;
