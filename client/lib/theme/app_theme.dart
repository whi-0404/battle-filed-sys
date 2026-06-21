import 'package:flutter/material.dart';
import '../proto/battlefield.pbenum.dart';
import '../models/radar_object.dart';

class AppTheme {
  AppTheme._();

  // ─── Colors ───────────────────────────────────────────────────
  static const Color bgDeep    = Color(0xFF040D1A);
  static const Color bgPanel   = Color(0xFF071628);
  static const Color bgCard    = Color(0xFF0D2137);
  static const Color bgCardHov = Color(0xFF122944);
  static const Color border    = Color(0xFF1A3A5C);
  static const Color borderGlow= Color(0xFF0F6FBA);

  static const Color accentBlue   = Color(0xFF00AAFF);
  static const Color accentGreen  = Color(0xFF00E676);
  static const Color accentOrange = Color(0xFFFF6D00);
  static const Color accentRed    = Color(0xFFFF1744);
  static const Color accentYellow = Color(0xFFFFD600);
  static const Color accentPurple = Color(0xFFD500F9);

  static const Color textPrimary   = Color(0xFFE0F0FF);
  static const Color textSecondary = Color(0xFF7BA7CC);
  static const Color textDim       = Color(0xFF3D6080);

  static const Color radarGreen = Color(0xFF00FF88);

  // ─── Object type colors ───────────────────────────────────────
  static Color objectColor(RadarObjectModel obj) {
    if (obj.isCivil) return accentBlue;
    switch (obj.type) {
      case ObjectType.UAV:     return accentGreen;
      case ObjectType.MISSILE: return accentRed;
      case ObjectType.THREAT:  return threatColor(obj.threatLevel);
      default: return textSecondary;
    }
  }

  static Color threatColor(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.LOW:      return accentGreen;
      case ThreatLevel.MEDIUM:   return accentYellow;
      case ThreatLevel.HIGH:     return accentOrange;
      case ThreatLevel.CRITICAL: return accentRed;
      default: return textSecondary;
    }
  }

  // ─── Object type icons ────────────────────────────────────────
  static IconData objectIcon(RadarObjectModel obj) {
    if (obj.isCivil) return Icons.flight;
    switch (obj.type) {
      case ObjectType.UAV:     return Icons.airplanemode_active;
      case ObjectType.MISSILE: return Icons.rocket_launch;
      case ObjectType.THREAT:  return Icons.warning_amber_rounded;
      default: return Icons.radio_button_unchecked;
    }
  }

  // ─── ThemeData ────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDeep,
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      secondary: accentGreen,
      surface: bgPanel,
      onSurface: textPrimary,
    ),
    cardTheme: const CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: border, width: 1),
      ),
    ),
    dividerColor: border,
    iconTheme: const IconThemeData(color: textSecondary),
  );
}
