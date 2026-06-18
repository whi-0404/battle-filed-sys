-- 002_add_military_support.down.sql
DROP INDEX IF EXISTS idx_aircraft_threat_level;
DROP INDEX IF EXISTS idx_aircraft_type_military;
DROP INDEX IF EXISTS idx_radar_snapshot_single;
DROP TABLE IF EXISTS radar_snapshot;
ALTER TABLE tracking DROP COLUMN IF EXISTS extra_data;
ALTER TABLE aircraft DROP COLUMN IF EXISTS threat_level;
