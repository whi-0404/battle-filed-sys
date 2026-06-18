package repository

import (
	"battlefiled-sys/internal/tracking/model"
	"context"

	"github.com/jmoiron/sqlx"
)

type PostgresRepository struct {
	db *sqlx.DB
}

func NewPostgresRepository(
	db *sqlx.DB,
) *PostgresRepository {

	return &PostgresRepository{
		db: db,
	}
}

func (r *PostgresRepository) UpdateCurrentTrack(
	ctx context.Context,
	track *model.Tracking,
) error {
	_, err := r.db.ExecContext(
		ctx,
		`
		INSERT INTO current_track(
			aircraft_id,
			lat,
			lon,
			alt,
			speed,
			heading,
			updated_at
		)
		VALUES ($1,$2,$3,$4,$5,$6,$7)
		ON CONFLICT (aircraft_id)
		DO UPDATE SET
			lat = EXCLUDED.lat,
			lon = EXCLUDED.lon,
			alt = EXCLUDED.alt,
			speed = EXCLUDED.speed,
			heading = EXCLUDED.heading,
			last_updated = EXCLUDED.last_updated
		`,
		track.Lat,
		track.Lon,
		track.Alt,
		track.Speed,
		track.Heading,
		track.LastUpdated,
	)
	if err != nil {
		return err
	}

	return nil
}

func (r *PostgresRepository) SaveTrackingHistory(
	ctx context.Context,
	history *model.TrackingHistory,
) error {
	_, err := r.db.ExecContext(
		ctx,
		`
		INSERT INTO track_history(
			id,
			aircraft_id,
			lat,
			lon,
			alt,
			speed,
			heading,
			snapshot_at
		)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)	

	`,
		history.ID,
		history.Lat,
		history.Lon,
		history.Alt,
		history.Speed,
		history.Heading,
		history.SnapshotAt,
	)
	if err != nil {
		return err
	}

	return nil
}

func (r *PostgresRepository) GetCurrentTrack(
	ctx context.Context,
	aircraftID string,
) (*model.Tracking, error) {
	var track model.Tracking

	err := r.db.GetContext(
		ctx,
		&track,
		`
			SELECT aircraft_id, lat, lon, alt, speed, heading, updated_at
			FROM current_track
			WHERE aircraft_id = $1
		`,
		aircraftID,
	)
	if err != nil {
		return nil, err
	}

	return &track, nil
}

func (r *PostgresRepository) SaveAircraft(
	ctx context.Context,
	aircraft *model.Aircraft,
) error {
	_, err := r.db.ExecContext(
		ctx,
		`
		INSERT INTO aircraft(
			icao24,
			callsign,
			type,
			Status,
			created_at,
			updated_at
		)
		VALUES ($1,$2,$3,$4,$5,$6)
		ON CONFLICT (icao24)
		DO UPDATE SET
			callsign = EXCLUDED.callsign,
			type = EXCLUDED.type,
			Status = EXCLUDED.Status,
		`,
		aircraft.ICAO24,
		aircraft.Callsign,
		aircraft.Type,
		aircraft.Status,
		aircraft.CreatedAt,
		aircraft.UpdatedAt,
	)
	if err != nil {
		return err
	}
	return nil
}
