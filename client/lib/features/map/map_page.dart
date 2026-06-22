import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/radar_object.dart';
import '../../providers/radar_provider.dart';
import '../../theme/app_theme.dart';
import '../object_list/object_list_panel.dart';
import '../object_detail/object_detail_page.dart';
import 'widgets/radar_marker.dart';
import 'widgets/stats_overlay.dart';
import 'widgets/compass_widget.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _panelOpen = false;
  RadarObjectModel? _selectedObject;

  // Animation controller cho panel slide
  late AnimationController _panelController;
  late Animation<Offset> _panelSlide;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadarProvider>().connect();
    });
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() => _panelOpen = !_panelOpen);
    if (_panelOpen) {
      _panelController.forward();
    } else {
      _panelController.reverse();
    }
  }

  void _closePanel() {
    setState(() => _panelOpen = false);
    _panelController.reverse();
  }

  void _onMarkerTap(RadarObjectModel obj) {
    // Center map on object
    _mapController.move(LatLng(obj.lat, obj.lon), _mapController.camera.zoom);
    // Navigate to detail
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ObjectDetailPage(object: obj),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          // ─── Map Layer ────────────────────────────────────────
          _buildMap(),

          // ─── Scan line overlay ────────────────────────────────
          _ScanLineOverlay(),

          // ─── Top HUD ─────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildTopHud(),
          ),

          // ─── Stats overlay (bottom left) ─────────────────────
          const Positioned(
            bottom: 24, left: 16,
            child: StatsOverlay(),
          ),

          // ─── Compass (bottom right) ───────────────────────────
          Positioned(
            bottom: 24, right: _panelOpen ? MediaQuery.of(context).size.width * 0.48 + 16 : 16,
            child: const CompassWidget(),
          ),

          // ─── Panel toggle button ──────────────────────────────
          Positioned(
            top: 0, bottom: 0,
            right: _panelOpen ? MediaQuery.of(context).size.width * 0.48 : 0,
            child: _buildPanelToggle(),
          ),

          // ─── Object List Panel ────────────────────────────────
          Positioned(
            top: 0, bottom: 0, right: 0,
            width: MediaQuery.of(context).size.width * 0.48,
            child: SlideTransition(
              position: _panelSlide,
              child: ObjectListPanel(
                onClose: _closePanel,
                onObjectTap: _onMarkerTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Consumer<RadarProvider>(
      builder: (ctx, provider, _) {
        final markers = provider.allObjects.map((obj) => _buildMarker(obj)).toList();
        return FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(16.0, 106.0),
            initialZoom: 3.0,
            minZoom: 2.0,
            maxZoom: 14.0,
            backgroundColor: AppTheme.bgDeep,
          ),
          children: [
            // Dark tile layer
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'battlefield.client',
            ),
            // Grid overlay
            _GridLayer(),
            // Object markers
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }

  Marker _buildMarker(RadarObjectModel obj) {
    return Marker(
      point: LatLng(obj.lat, obj.lon),
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => _onMarkerTap(obj),
        child: RadarMarker(object: obj),
      ),
    );
  }

  Widget _buildTopHud() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.bgDeep.withOpacity(0.95), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 20,
      ),
      child: Consumer<RadarProvider>(
        builder: (_, provider, __) => Row(
          children: [
            // Logo/Title
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.radarGreen, width: 2),
                    color: AppTheme.radarGreen.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.radar, color: AppTheme.radarGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BATTLEFIELD RADAR',
                      style: TextStyle(
                        color: AppTheme.radarGreen, fontSize: 14,
                        fontWeight: FontWeight.w800, letterSpacing: 3,
                      ),
                    ),
                    Text('SYSTEM ACTIVE',
                      style: TextStyle(
                        color: AppTheme.radarGreen.withOpacity(0.6),
                        fontSize: 9, letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Connection status
            _ConnectionBadge(connected: provider.connected),
            const SizedBox(width: 12),
            // Object count badge
            _CountBadge(count: provider.stats.totalObjects),
            const SizedBox(width: 8),
            // Threat badge
            if (provider.stats.criticalThreats > 0)
              _ThreatBadge(count: provider.stats.criticalThreats),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelToggle() {
    return Center(
      child: GestureDetector(
        onTap: _togglePanel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 28,
          height: 80,
          decoration: BoxDecoration(
            color: _panelOpen ? AppTheme.accentBlue : AppTheme.bgCard,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            border: Border.all(
              color: _panelOpen ? AppTheme.accentBlue : AppTheme.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentBlue.withOpacity(_panelOpen ? 0.4 : 0.1),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(
            _panelOpen ? Icons.chevron_right : Icons.list,
            color: _panelOpen ? Colors.white : AppTheme.textSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Scan line animation ───────────────────────────────────────────

class _ScanLineOverlay extends StatefulWidget {
  @override
  State<_ScanLineOverlay> createState() => _ScanLineOverlayState();
}

class _ScanLineOverlayState extends State<_ScanLineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ScanLinePainter(_ctrl.value),
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          AppTheme.radarGreen.withOpacity(0.06),
          AppTheme.radarGreen.withOpacity(0.12),
          AppTheme.radarGreen.withOpacity(0.06),
          Colors.transparent,
        ],
        stops: const [0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 40, size.width, 80));
    canvas.drawRect(Rect.fromLTWH(0, y - 40, size.width, 80), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}

// ─── Grid overlay ─────────────────────────────────────────────────

class _GridLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.border.withOpacity(0.25)
      ..strokeWidth = 0.5;
    const spacing = 80.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── HUD widgets ──────────────────────────────────────────────────

class _ConnectionBadge extends StatelessWidget {
  final bool connected;
  const _ConnectionBadge({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (connected ? AppTheme.accentGreen : AppTheme.accentRed).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connected ? AppTheme.accentGreen : AppTheme.accentRed,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? AppTheme.accentGreen : AppTheme.accentRed,
            ),
          ).animate(onPlay: (c) => c.repeat())
            .fadeOut(duration: 800.ms)
            .then()
            .fadeIn(duration: 800.ms),
          const SizedBox(width: 6),
          Text(
            connected ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              color: connected ? AppTheme.accentGreen : AppTheme.accentRed,
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radar, color: AppTheme.accentBlue, size: 12),
          const SizedBox(width: 5),
          Text('$count OBJECTS',
            style: const TextStyle(
              color: AppTheme.accentBlue, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatBadge extends StatelessWidget {
  final int count;
  const _ThreatBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentRed),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 12),
          const SizedBox(width: 5),
          Text('$count CRITICAL',
            style: const TextStyle(
              color: AppTheme.accentRed, fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat())
      .shimmer(duration: 1200.ms, color: AppTheme.accentRed.withOpacity(0.3));
  }
}
