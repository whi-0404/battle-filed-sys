import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CompassWidget extends StatelessWidget {
  const CompassWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.bgPanel.withOpacity(0.85),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12),
        ],
      ),
      child: CustomPaint(
        painter: _CompassPainter(),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    // Outer ring
    canvas.drawCircle(
      center, r,
      Paint()
        ..color = AppTheme.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Cardinal directions
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final dirs = [('N', 0.0), ('E', 90.0), ('S', 180.0), ('W', 270.0)];
    for (final (label, deg) in dirs) {
      final rad = deg * 3.14159 / 180;
      final tx = center.dx + (r - 10) * _sin(rad) - 4;
      final ty = center.dy - (r - 10) * _cos(rad) - 5;
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: label == 'N' ? AppTheme.accentRed : AppTheme.textDim,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(tx, ty));
    }

    // N arrow (red)
    final northPaint = Paint()..color = AppTheme.accentRed;
    final southPaint = Paint()..color = AppTheme.textDim;
    final path1 = Path();
    path1.moveTo(center.dx, center.dy - 12);
    path1.lineTo(center.dx - 4, center.dy);
    path1.lineTo(center.dx + 4, center.dy);
    path1.close();
    canvas.drawPath(path1, northPaint);

    final path2 = Path();
    path2.moveTo(center.dx, center.dy + 12);
    path2.lineTo(center.dx - 4, center.dy);
    path2.lineTo(center.dx + 4, center.dy);
    path2.close();
    canvas.drawPath(path2, southPaint);

    // Center dot
    canvas.drawCircle(center, 2.5, Paint()..color = AppTheme.textPrimary);
  }

  double _sin(double x) => x - x*x*x/6 + x*x*x*x*x/120;
  double _cos(double x) => _sin(x + 1.5707963);

  @override
  bool shouldRepaint(_) => false;
}
