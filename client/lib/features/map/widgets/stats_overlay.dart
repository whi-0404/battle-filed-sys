import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/radar_provider.dart';
import '../../../theme/app_theme.dart';

class StatsOverlay extends StatelessWidget {
  const StatsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RadarProvider>(
      builder: (_, provider, __) {
        final s = provider.stats;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgPanel.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _label('RADAR STATUS'),
              const SizedBox(height: 8),
              _row(Icons.flight, 'Civil', s.civilAircraft, AppTheme.accentBlue),
              _row(Icons.airplanemode_active, 'UAV', s.uavCount, AppTheme.accentGreen),
              _row(Icons.rocket_launch, 'Missile', s.missileCount, AppTheme.accentRed),
              _row(Icons.warning_amber_rounded, 'Threat', s.threatCount, AppTheme.accentOrange),
              const Divider(color: AppTheme.border, height: 16),
              _row(Icons.track_changes, 'Total', s.totalObjects, AppTheme.textPrimary),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.radarGreen,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    ),
  );

  Widget _row(IconData icon, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          SizedBox(
            width: 48,
            child: Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
          Text('$count',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
