import 'package:flutter/material.dart';

import '../core/theme/design_system.dart';

class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          surface: AppColors.card,
          secondary: AppColors.secondary,
          tertiary: AppColors.accent,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(Brightness.light),
    );

    return _applyCommon(base, isDark: false);
  }

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          surface: AppColors.darkSurface,
          secondary: AppColors.secondary,
          tertiary: AppColors.accent,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _textTheme(Brightness.dark),
    );

    return _applyCommon(base, isDark: true);
  }

  static ThemeData _applyCommon(ThemeData base, {required bool isDark}) {
    final radius = BorderRadius.circular(24);
    final borderSide = BorderSide(color: base.colorScheme.outlineVariant);

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: base.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: base.colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black26,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: base.colorScheme.surfaceContainerLowest,
        labelStyle: TextStyle(color: base.colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      dividerTheme: DividerThemeData(
        color: base.colorScheme.outlineVariant.withOpacity(0.4),
        thickness: 1,
        space: 32,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: base.colorScheme.onSurface,
          backgroundColor: base.colorScheme.surface,
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: base.colorScheme.outline),
          foregroundColor: base.colorScheme.onSurface,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? base.colorScheme.surfaceContainer : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 1.8),
        ),
        labelStyle: base.textTheme.bodyMedium?.copyWith(
          color: base.colorScheme.onSurface.withOpacity(0.8),
        ),
        prefixIconColor: base.colorScheme.primary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: base.colorScheme.primary,
        unselectedItemColor: base.colorScheme.onSurfaceVariant.withOpacity(0.5),
        backgroundColor: Colors.transparent,
        showUnselectedLabels: false,
      ),
      extensions: [
        AppDecorations(
          heroGradient: const LinearGradient(
            colors: [Color(0xFF6F6BFF), Color(0xFF8F7CFF), Color(0xFF4DD0E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          cardGradient: LinearGradient(
            colors: [
              base.colorScheme.surface.withOpacity(isDark ? 0.7 : 0.96),
              base.colorScheme.surface.withOpacity(isDark ? 0.5 : 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          glow: [
            BoxShadow(
              color: base.colorScheme.primary.withOpacity(0.18),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
          frostedTint: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.7),
        ),
      ],
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;

    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(
        color: brightness == Brightness.dark
            ? Colors.white70
            : AppColors.textMuted,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: brightness == Brightness.dark
            ? Colors.white70
            : AppColors.textMuted,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
