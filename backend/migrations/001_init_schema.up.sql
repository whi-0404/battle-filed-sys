CREATE TABLE IF NOT EXISTS aircraft (
    id UUID PRIMARY KEY,

    type VARCHAR(30) NOT NULL,

    status VARCHAR(30) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL,

    updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS tracking (

    object_id UUID PRIMARY KEY,

    latitude DOUBLE PRECISION NOT NULL,

    longitude DOUBLE PRECISION NOT NULL,

    altitude DOUBLE PRECISION NOT NULL,

    heading DOUBLE PRECISION NOT NULL,

    speed DOUBLE PRECISION NOT NULL,

    last_updated TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_tracking_aircraft
        FOREIGN KEY (object_id)
        REFERENCES aircraft(id)
);


CREATE TABLE IF NOT EXISTS  track_history (

    id UUID PRIMARY KEY,

    object_id UUID NOT NULL,

    latitude DOUBLE PRECISION NOT NULL,

    longitude DOUBLE PRECISION NOT NULL,

    altitude DOUBLE PRECISION NOT NULL,

    heading DOUBLE PRECISION NOT NULL,

    speed DOUBLE PRECISION NOT NULL,

    snapshot_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_history_aircraft
        FOREIGN KEY (object_id)
        REFERENCES aircraft(id)
);

CREATE INDEX IF NOT EXISTS idx_track_history_object_id   ON track_history (object_id, snapshot_at DESC);
CREATE INDEX IF NOT EXISTS idx_track_history_snapshot_at ON track_history (snapshot_at DESC);
CREATE INDEX IF NOT EXISTS idx_aircraft_type             ON aircraft (type);
CREATE INDEX IF NOT EXISTS idx_aircraft_status           ON aircraft (status);