import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../proto/battlefield.pbenum.dart';
import '../../models/radar_object.dart';
import '../../theme/app_theme.dart';

class ObjectDetailPage extends StatelessWidget {
  final RadarObjectModel object;
  final VoidCallback? onClose;
  const ObjectDetailPage({super.key, required this.object, this.onClose});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.objectColor(object);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: CustomScrollView(
        slivers: [
          // ─── SliverAppBar ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.bgPanel,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.bgCard,
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 16),
              ),
              onPressed: () {
                if (onClose != null) {
                  onClose!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildMiniMap(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: _buildObjectHeader(color),
            ),
          ),

          // ─── Detail content ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Identity section
                _buildSection('IDENTIFICATION', [
                  _DetailRow('ID', object.id, Icons.fingerprint),
                  _DetailRow('Callsign', object.displayName, Icons.badge),
                  _DetailRow('Type', object.typeLabel, Icons.category),
                  _DetailRow('Layer', object.layer.name, Icons.layers),
                ], color),

                const SizedBox(height: 16),

                // Position section
                _buildSection('POSITION', [
                  _DetailRow('Latitude', '${object.lat.toStringAsFixed(6)}°', Icons.gps_fixed),
                  _DetailRow('Longitude', '${object.lon.toStringAsFixed(6)}°', Icons.gps_not_fixed),
                  _DetailRow('Altitude', '${object.alt.toStringAsFixed(0)} m  (${(object.alt / 1000).toStringAsFixed(2)} km)', Icons.height),
                ], color),

                const SizedBox(height: 16),

                // Motion section
                _buildSection('MOTION', [
                  _DetailRow('Speed', '${object.speed.toStringAsFixed(1)} kts  (${(object.speed * 1.852).toStringAsFixed(1)} km/h)', Icons.speed),
                  _DetailRow('Heading', '${object.heading.toStringAsFixed(1)}°  ${_headingLabel(object.heading)}', Icons.navigation),
                ], color),

                const SizedBox(height: 16),

                // Status section
                if (object.isMilitary) ...[
                  _buildSection('THREAT ASSESSMENT', [
                    _ThreatLevelRow(level: object.threatLevel),
                    _DetailRow('Status', object.status, Icons.radio_button_checked),
                  ], color),
                  const SizedBox(height: 16),
                ],

                // Timestamp
                _buildSection('TRACKING', [
                  _DetailRow(
                    'Last Updated',
                    DateFormat('HH:mm:ss.SSS dd/MM/yyyy').format(object.lastUpdated.toLocal()),
                    Icons.access_time,
                  ),
                ], color),

                const SizedBox(height: 32),

                // Vector display
                _buildVectorDisplay(color),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMap() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(object.lat, object.lon),
        initialZoom: 9.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'battlefield.client',
        ),
        MarkerLayer(markers: [
          Marker(
            point: LatLng(object.lat, object.lon),
            width: 24, height: 24,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.objectColor(object),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildObjectHeader(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        border: Border(
          top: BorderSide(color: color.withOpacity(0.3)),
          bottom: const BorderSide(color: AppTheme.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color, width: 1.5),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12)],
            ),
            child: Icon(AppTheme.objectIcon(object), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(object.displayName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Text(object.typeLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    if (object.id != object.displayName) ...[
                      const Text(' · ', style: TextStyle(color: AppTheme.textDim, fontSize: 11)),
                      Text(object.id,
                        style: const TextStyle(color: AppTheme.textDim, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (object.isMilitary)
            _ThreatBadge(level: object.threatLevel),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Container(width: 3, height: 12, color: accent,
                  margin: const EdgeInsets.only(right: 8)),
                Text(title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.border, height: 1),
          ...rows,
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildVectorDisplay(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 3, height: 12, color: color,
                margin: const EdgeInsets.only(right: 8)),
              Text('VECTOR DISPLAY',
                style: TextStyle(
                  color: color, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomPaint(
            size: const Size(double.infinity, 120),
            painter: _VectorPainter(object.heading, color),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  String _headingLabel(double heading) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    return dirs[((heading + 22.5) / 45).floor().clamp(0, 8)];
  }
}

// ─── Detail Row ───────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _DetailRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textDim),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label,
              style: const TextStyle(color: AppTheme.textDim, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Threat level row ─────────────────────────────────────────────

class _ThreatLevelRow extends StatelessWidget {
  final ThreatLevel level;
  const _ThreatLevelRow({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.threatColor(level);
    final levels = [
      ThreatLevel.LOW, ThreatLevel.MEDIUM,
      ThreatLevel.HIGH, ThreatLevel.CRITICAL,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.shield, size: 14, color: AppTheme.textDim),
          const SizedBox(width: 10),
          const SizedBox(
            width: 90,
            child: Text('Threat Level',
              style: TextStyle(color: AppTheme.textDim, fontSize: 11),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Threat bar
                ...levels.map((l) => Container(
                  width: 20, height: 8,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: l.value <= level.value
                        ? AppTheme.threatColor(l)
                        : AppTheme.border,
                  ),
                )),
                const SizedBox(width: 8),
                Text(level.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Threat badge ─────────────────────────────────────────────────

class _ThreatBadge extends StatelessWidget {
  final ThreatLevel level;
  const _ThreatBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.threatColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, color: color, size: 16),
          const SizedBox(height: 2),
          Text(level.name,
            style: TextStyle(
              color: color, fontSize: 8,
              fontWeight: FontWeight.w800, letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vector painter ───────────────────────────────────────────────

class _VectorPainter extends CustomPainter {
  final double heading;
  final Color color;
  _VectorPainter(this.heading, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.height / 2 - 10;

    // Background circle
    canvas.drawCircle(center, r,
      Paint()
        ..color = AppTheme.bgDeep
        ..style = PaintingStyle.fill);
    canvas.drawCircle(center, r,
      Paint()
        ..color = AppTheme.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);

    // Tick marks
    final tickPaint = Paint()
      ..color = AppTheme.textDim.withOpacity(0.4)
      ..strokeWidth = 1;
    for (int i = 0; i < 36; i++) {
      final rad = i * 10.0 * 3.14159265 / 180;
      final s = _sin(rad); final c = _cos(rad);
      final inner = i % 9 == 0 ? r - 10 : r - 5;
      canvas.drawLine(
        Offset(center.dx + inner * s, center.dy - inner * c),
        Offset(center.dx + r * s, center.dy - r * c),
        tickPaint,
      );
    }

    // Heading arrow
    final rad = heading * 3.14159265 / 180;
    final arrowLen = r - 14;
    final tipX = center.dx + arrowLen * _sin(rad);
    final tipY = center.dy - arrowLen * _cos(rad);
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(tipX, tipY), arrowPaint);

    // Arrowhead
    final ah = 10.0;
    final aw = 5.0;
    final path = ui.Path();
    path.moveTo(tipX, tipY);
    path.lineTo(
      tipX - ah * _sin(rad) + aw * _cos(rad),
      tipY + ah * _cos(rad) + aw * _sin(rad),
    );
    path.lineTo(
      tipX - ah * _sin(rad) - aw * _cos(rad),
      tipY + ah * _cos(rad) - aw * _sin(rad),
    );
    path.close();
    canvas.drawPath(path, Paint()..color = color);

    // Heading text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${heading.toStringAsFixed(0)}°',
        style: TextStyle(
          color: color, fontSize: 13, fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    // N label
    final nPainter = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(color: AppTheme.accentRed, fontSize: 10, fontWeight: FontWeight.w800),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    nPainter.paint(canvas, Offset(center.dx - nPainter.width / 2, center.dy - r + 2));
  }

  double _sin(double x) => x - x*x*x/6 + x*x*x*x*x/120 - x*x*x*x*x*x*x/5040;
  double _cos(double x) => _sin(x + 1.5707963268);

  @override
  bool shouldRepaint(_VectorPainter old) =>
      old.heading != heading || old.color != color;
}
