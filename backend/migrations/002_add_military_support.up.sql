
ALTER TABLE aircraft
    ADD COLUMN IF NOT EXISTS threat_level VARCHAR(20) NOT NULL DEFAULT 'LOW';

CREATE INDEX IF NOT EXISTS idx_aircraft_type_military
    ON aircraft (type)
    WHERE type IN ('UAV', 'MISSILE', 'THREAT');

CREATE INDEX IF NOT EXISTS idx_aircraft_threat_level
    ON aircraft (threat_level)
    WHERE threat_level IN ('HIGH', 'CRITICAL');

ALTER TABLE tracking
    ADD COLUMN IF NOT EXISTS extra_data JSONB;

CREATE TABLE IF NOT EXISTS radar_snapshot (
    id           SERIAL PRIMARY KEY,
    snapshot_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    payload      JSONB       NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_radar_snapshot_single
    ON radar_snapshot ((true));
