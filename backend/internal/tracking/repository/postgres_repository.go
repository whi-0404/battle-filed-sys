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
		INSERT INTO tracking (
			icao24,
			latitude,
			longitude,
			altitude,
			speed,
			heading,
			last_updated
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (icao24)
		DO UPDATE SET
			latitude = EXCLUDED.latitude,
			longitude = EXCLUDED.longitude,
			altitude = EXCLUDED.altitude,
			speed = EXCLUDED.speed,
			heading = EXCLUDED.heading,
			last_updated = EXCLUDED.last_updated
		`,
		track.ICAO24,
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
		INSERT INTO track_history (
			icao24,
			latitude,
			longitude,
			altitude,
			speed,
			heading,
			snapshot_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		`,
		history.ICAO24,
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
			SELECT icao24, latitude, longitude, altitude, speed, heading, last_updated
			FROM tracking
			WHERE icao24 = $1
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
		INSERT INTO aircraft (
			icao24,
			callsign,
			type,
			status,
			created_at,
			updated_at
		)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (icao24)
		DO UPDATE SET
			callsign = EXCLUDED.callsign,
			type = EXCLUDED.type,
			status = EXCLUDED.status,
			updated_at = EXCLUDED.updated_at
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

func (r *PostgresRepository) BulkUpdateCurrentTrack(
	ctx context.Context,
	tracks []*model.Tracking,
) error {
	if len(tracks) == 0 {
		return nil
	}
	_, err := r.db.NamedExecContext(
		ctx,
		`
		INSERT INTO tracking (
			icao24,
			latitude,
			longitude,
			altitude,
			speed,
			heading,
			last_updated
		)
		VALUES (:icao24, :latitude, :longitude, :altitude, :speed, :heading, :last_updated)
		ON CONFLICT (icao24)
		DO UPDATE SET
			latitude = EXCLUDED.latitude,
			longitude = EXCLUDED.longitude,
			altitude = EXCLUDED.altitude,
			speed = EXCLUDED.speed,
			heading = EXCLUDED.heading,
			last_updated = EXCLUDED.last_updated
		`,
		tracks,
	)
	return err
}

func (r *PostgresRepository) BulkSaveAircraft(
	ctx context.Context,
	aircrafts []*model.Aircraft,
) error {
	if len(aircrafts) == 0 {
		return nil
	}
	_, err := r.db.NamedExecContext(
		ctx,
		`
		INSERT INTO aircraft (
			icao24,
			callsign,
			type,
			status,
			created_at,
			updated_at
		)
		VALUES (:icao24, :callsign, :type, :status, :created_at, :updated_at)
		ON CONFLICT (icao24)
		DO UPDATE SET
			callsign = EXCLUDED.callsign,
			type = EXCLUDED.type,
			status = EXCLUDED.status,
			updated_at = EXCLUDED.updated_at
		`,
		aircrafts,
	)
	return err
}
