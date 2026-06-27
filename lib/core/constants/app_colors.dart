import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette – Bangladesh flag inspired deep green + crimson
  static const Color primary       = Color(0xFF006A4E);
  static const Color primaryDark   = Color(0xFF004D38);
  static const Color primaryLight  = Color(0xFFE8F5E9);

  static const Color accent        = Color(0xFFF42A41); // Flag Crimson
  static const Color accentLight   = Color(0xFFFFF0F1);

  static const Color gold          = Color(0xFFFFB300);
  static const Color goldLight     = Color(0xFFFFF8E1);

  // Semantic
  static const Color error         = Color(0xFFD32F2F);
  static const Color success       = Color(0xFF2E7D32);
  static const Color warning       = Color(0xFFF9A825);
  static const Color info          = Color(0xFF0288D1);

  // Backgrounds
  static const Color background    = Color(0xFFF4F7F6);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceVariant= Color(0xFFF0F4F3);

  // Text
  static const Color textPrimary   = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint      = Color(0xFFAAAAAA);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B2FA0), Color(0xFF006A4E)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF006A4E), Color(0xFF00897B)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
  );

  static const LinearGradient adminGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A237E), Color(0xFF283593)],
  );
}
