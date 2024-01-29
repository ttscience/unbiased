-- Create a table for storing application settings
CREATE EXTENSION temporal_tables;

CREATE TABLE settings (
  key         TEXT NOT NULL,
  value       TEXT NOT NULL
);

-- Insert initial schema version setting if it doesn't exist
INSERT INTO settings (key, value)
VALUES ('schema_version', '0.0.0.9003');
