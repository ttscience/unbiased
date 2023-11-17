CREATE EXTENSION temporal_tables;

CREATE TABLE settings (
  key         TEXT NOT NULL,
  value       TEXT NOT NULL
);

INSERT INTO settings (key, value)
VALUES ('schema_version', '0.0.0.9003');
