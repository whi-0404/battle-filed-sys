package service

import (
	"battlefiled-sys/internal/tracking/model"
	"battlefiled-sys/internal/tracking/repository"
	"context"
)

type TrackingService struct {
	repo repository.TrackingRepository
}

func NewTrackingService(
	repo repository.TrackingRepository,
) *TrackingService {
	return &TrackingService{
		repo: repo,
	}
}

func (s *TrackingService) UpdateTrackingCurrent(
	ctx context.Context,
	track *model.Tracking,
) error {
	return s.repo.UpdateCurrentTrack(ctx, track)
}

func (s *TrackingService) SaveTrackingHistory(
	ctx context.Context,
	history *model.TrackingHistory,
) error {
	return s.repo.SaveTrackingHistory(ctx, history)
}
func (s *TrackingService) SaveAircraft(
	ctx context.Context,
	aircraft *model.Aircraft,
) error {
	return s.repo.SaveAircraft(ctx, aircraft)
}

func (s *TrackingService) BulkUpdateCurrentTrack(
	ctx context.Context,
	tracks []*model.Tracking,
) error {
	return s.repo.BulkUpdateCurrentTrack(ctx, tracks)
}

func (s *TrackingService) BulkSaveAircraft(
	ctx context.Context,
	aircrafts []*model.Aircraft,
) error {
	return s.repo.BulkSaveAircraft(ctx, aircrafts)
}
