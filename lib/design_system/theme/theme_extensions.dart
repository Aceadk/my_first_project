import 'package:flutter/material.dart';

@immutable
class CrushThemeEffects extends ThemeExtension<CrushThemeEffects> {
  const CrushThemeEffects({
    required this.glowColor,
    required this.glassSurface,
    required this.glassBorder,
    required this.shadowOpacity,
    required this.motionScale,
    required this.primaryGradient,
  });

  final Color glowColor;
  final Color glassSurface;
  final Color glassBorder;
  final double shadowOpacity;
  final double motionScale;
  final LinearGradient primaryGradient;

  @override
  CrushThemeEffects copyWith({
    Color? glowColor,
    Color? glassSurface,
    Color? glassBorder,
    double? shadowOpacity,
    double? motionScale,
    LinearGradient? primaryGradient,
  }) {
    return CrushThemeEffects(
      glowColor: glowColor ?? this.glowColor,
      glassSurface: glassSurface ?? this.glassSurface,
      glassBorder: glassBorder ?? this.glassBorder,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      motionScale: motionScale ?? this.motionScale,
      primaryGradient: primaryGradient ?? this.primaryGradient,
    );
  }

  @override
  CrushThemeEffects lerp(ThemeExtension<CrushThemeEffects>? other, double t) {
    if (other is! CrushThemeEffects) return this;
    return CrushThemeEffects(
      glowColor: Color.lerp(glowColor, other.glowColor, t) ?? glowColor,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t) ?? glassSurface,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t) ?? glassBorder,
      shadowOpacity: shadowOpacity + (other.shadowOpacity - shadowOpacity) * t,
      motionScale: motionScale + (other.motionScale - motionScale) * t,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t) ??
          primaryGradient,
    );
  }
}

