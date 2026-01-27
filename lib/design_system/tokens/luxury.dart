import 'package:flutter/material.dart';

class DsLuxuryColors {
  DsLuxuryColors._();

  // AMOLED base
  static const Color black = Color(0xFF000000);
  static const Color blackSoft = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF111116);
  static const Color surfaceElevated = Color(0xFF1A1A22);

  // Premium accents
  static const Color gold = Color(0xFFD7B46A);
  static const Color goldDeep = Color(0xFFB9903D);
  static const Color royalPurple = Color(0xFF3A1B5A);
  static const Color neonMint = Color(0xFF3FF2C5);

  // Luxury text
  static const Color textPrimary = Color(0xFFF6F1E8);
  static const Color textMuted = Color(0xFFB8AFA0);

  // Glass/metallic
  static const Color glass = Color(0xCC121219);
  static const Color glassBorder = Color(0x40D7B46A);
  static const Color glow = Color(0x66D7B46A);
}

class DsLuxuryGradients {
  DsLuxuryGradients._();

  static const LinearGradient goldSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DsLuxuryColors.gold,
      DsLuxuryColors.goldDeep,
    ],
  );

  static const LinearGradient noirPlum = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DsLuxuryColors.black,
      DsLuxuryColors.royalPurple,
    ],
  );
}

