package repository

import (
	"battlefiled-sys/internal/tracking/model"
	"context"
)

type TrackingRepository interface {
	UpdateCurrentTrack(
		ctx context.Context,
		track *model.Tracking,
	) error

	SaveTrackingHistory(
		ctx context.Context,
		history *model.TrackingHistory,
	) error

	SaveAircraft(
		ctx context.Context,
		aircraft *model.Aircraft,
	) error

	BulkUpdateCurrentTrack(
		ctx context.Context,
		tracks []*model.Tracking,
	) error

	BulkSaveAircraft(
		ctx context.Context,
		aircrafts []*model.Aircraft,
	) error
}
