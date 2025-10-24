import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6F6BFF);
  static const Color secondary = Color(0xFFFF6F91);
  static const Color accent = Color(0xFF4DD0E1);
  static const Color background = Color(0xFFF5F7FB);
  static const Color card = Colors.white;
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF475467);
  static const Color success = Color(0xFF2EC4B6);
  static const Color warning = Color(0xFFF4AE3F);
  static const Color danger = Color(0xFFF97066);
}

class AppDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 420);
  static const Duration long = Duration(milliseconds: 800);
}

@immutable
class AppDecorations extends ThemeExtension<AppDecorations> {
  const AppDecorations({
    required this.heroGradient,
    required this.cardGradient,
    required this.glow,
    required this.frostedTint,
  });

  final Gradient heroGradient;
  final Gradient cardGradient;
  final List<BoxShadow> glow;
  final Color frostedTint;

  @override
  ThemeExtension<AppDecorations> copyWith({
    Gradient? heroGradient,
    Gradient? cardGradient,
    List<BoxShadow>? glow,
    Color? frostedTint,
  }) {
    return AppDecorations(
      heroGradient: heroGradient ?? this.heroGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      glow: glow ?? this.glow,
      frostedTint: frostedTint ?? this.frostedTint,
    );
  }

  @override
  ThemeExtension<AppDecorations> lerp(
    ThemeExtension<AppDecorations>? other,
    double t,
  ) {
    if (other is! AppDecorations) return this;
    return AppDecorations(
      heroGradient: Gradient.lerp(heroGradient, other.heroGradient, t)!,
      cardGradient: Gradient.lerp(cardGradient, other.cardGradient, t)!,
      glow: other.glow, // glow arrays are tiny; just switch to target list
      frostedTint: Color.lerp(frostedTint, other.frostedTint, t)!,
    );
  }
}
