-- 002_add_military_support.up.sql
-- Thêm hỗ trợ cho military objects (UAV, Missile, Threat)

-- Thêm threat_level vào bảng aircraft
ALTER TABLE aircraft
    ADD COLUMN IF NOT EXISTS threat_level VARCHAR(20) NOT NULL DEFAULT 'LOW';

-- Index tối ưu cho filter theo type quân sự và civil
CREATE INDEX IF NOT EXISTS idx_aircraft_type_military
    ON aircraft (type)
    WHERE type IN ('UAV', 'MISSILE', 'THREAT');

CREATE INDEX IF NOT EXISTS idx_aircraft_threat_level
    ON aircraft (threat_level)
    WHERE threat_level IN ('HIGH', 'CRITICAL');

-- Thêm cột extra_data (JSONB) vào tracking để lưu thông tin đặc thù của từng loại
ALTER TABLE tracking
    ADD COLUMN IF NOT EXISTS extra_data JSONB;

-- Bảng radar_snapshot: lưu snapshot gần nhất để WebSocket client reconnect nhanh
CREATE TABLE IF NOT EXISTS radar_snapshot (
    id           SERIAL PRIMARY KEY,
    snapshot_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    payload      JSONB       NOT NULL
);

-- Chỉ giữ 1 row duy nhất (rolling snapshot)
CREATE UNIQUE INDEX IF NOT EXISTS idx_radar_snapshot_single
    ON radar_snapshot ((true));
