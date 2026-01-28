import 'package:flutter/material.dart';

/// Gold & Black Luxury - Classic (Royal) palette.
class DsLuxuryColors {
  DsLuxuryColors._();

  // Core
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceElevated = Color(0xFF141414);

  // Gold accents (metallic)
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldSoft = Color(0xFFF1D27A);
  static const Color goldDark = Color(0xFF9E7C19);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF7A7A7A);
  static const Color textOnGold = Color(0xFF1A1A1A);

  // Borders & dividers
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderGold = Color(0xFF6B5A1E);

  // UI elements
  static const Color card = surface;
  static const Color inputBackground = Color(0xFF111111);
  static const Color iconPrimary = goldPrimary;
  static const Color iconSecondary = Color(0xFFAAAAAA);

  // States
  static const Color success = Color(0xFF3CB371);
  static const Color error = Color(0xFFE05A5A);
  static const Color warning = Color(0xFFE6B566);

  // Effects
  static const Color glowGold = Color(0x33D4AF37);
  static const Color shimmerGold = Color(0x66F1D27A);
  static const Color glass = Color(0xCC0D0D0D);
  static const Color glassBorder = Color(0x406B5A1E);

  // Aliases for compatibility
  static const Color black = background;
  static const Color blackSoft = Color(0xFF0A0A0A);
  static const Color gold = goldPrimary;
  static const Color goldDeep = goldDark;
  static const Color glow = glowGold;
}

class DsLuxuryGradients {
  DsLuxuryGradients._();

  static const LinearGradient goldSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DsLuxuryColors.goldDark,
      DsLuxuryColors.goldPrimary,
      DsLuxuryColors.goldSoft,
    ],
  );

  static const LinearGradient premiumBadge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DsLuxuryColors.goldDark,
      DsLuxuryColors.goldPrimary,
      DsLuxuryColors.goldSoft,
    ],
  );
}

/// Gold & Black Luxury - Modern palette.
class DsLuxuryModernColors {
  DsLuxuryModernColors._();

  // Core
  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF101010);
  static const Color surfaceElevated = Color(0xFF181818);

  // Gold accents (cooler tone)
  static const Color goldPrimary = Color(0xFFE6C77D);
  static const Color goldSoft = Color(0xFFF5E6B0);
  static const Color goldDark = Color(0xFFB89B4F);

  // Text
  static const Color textPrimary = Color(0xFFF2F2F2);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF808080);
  static const Color textOnGold = Color(0xFF121212);

  // Borders & dividers
  static const Color border = Color(0xFF262626);
  static const Color borderGold = Color(0xFF7D6A33);

  // UI elements
  static const Color card = surface;
  static const Color inputBackground = Color(0xFF141414);
  static const Color iconPrimary = goldPrimary;
  static const Color iconSecondary = Color(0xFF999999);

  // States
  static const Color success = Color(0xFF4CAF84);
  static const Color error = Color(0xFFE57373);
  static const Color warning = Color(0xFFF0C674);

  // Effects
  static const Color glowGold = Color(0x2AE6C77D);
  static const Color shimmerGold = Color(0x55F5E6B0);
  static const Color glass = Color(0xCC101010);
  static const Color glassBorder = Color(0x407D6A33);
}

class DsLuxuryModernGradients {
  DsLuxuryModernGradients._();

  static const LinearGradient goldSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DsLuxuryModernColors.goldDark,
      DsLuxuryModernColors.goldPrimary,
      DsLuxuryModernColors.goldSoft,
    ],
  );

  static const LinearGradient premiumBadge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DsLuxuryModernColors.goldDark,
      DsLuxuryModernColors.goldPrimary,
      DsLuxuryModernColors.goldSoft,
    ],
  );
}
