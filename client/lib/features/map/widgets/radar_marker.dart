import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../proto/battlefield.pbenum.dart';
import '../../../models/radar_object.dart';
import '../../../theme/app_theme.dart';

class RadarMarker extends StatelessWidget {
  final RadarObjectModel object;
  const RadarMarker({super.key, required this.object});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.objectColor(object);
    final icon = AppTheme.objectIcon(object);
    final isPulsing = object.type == ObjectType.MISSILE ||
        object.threatLevel == ThreatLevel.CRITICAL;

    Widget marker = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 18),
    );

    if (isPulsing) {
      marker = Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.08),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
          ).animate(onPlay: (c) => c.repeat())
            .scaleXY(begin: 0.8, end: 1.2, duration: 1000.ms)
            .fadeOut(duration: 1000.ms),
          marker,
        ],
      );
    }

    // Heading indicator
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(44, 44),
          painter: _HeadingPainter(object.heading, color),
        ),
        marker,
      ],
    );
  }
}

class _HeadingPainter extends CustomPainter {
  final double heading;
  final Color color;
  _HeadingPainter(this.heading, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rad = heading * math.pi / 180.0;
    final tipX = center.dx + 20 * math.sin(rad);
    final tipY = center.dy - 20 * math.cos(rad);
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(tipX, tipY), paint);
  }

  @override
  bool shouldRepaint(_HeadingPainter old) =>
      old.heading != heading || old.color != color;
}
