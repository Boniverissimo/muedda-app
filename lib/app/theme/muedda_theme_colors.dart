import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class MueddaThemeColors extends ThemeExtension<MueddaThemeColors> {
  const MueddaThemeColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.shadow,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color shadow;

  factory MueddaThemeColors.light() => const MueddaThemeColors(
        canvas: AppColors.background,
        surface: AppColors.surface,
        surfaceMuted: AppColors.surfaceVariant,
        border: AppColors.border,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        textTertiary: AppColors.textTertiary,
        shadow: Color(0x12000000),
      );

  factory MueddaThemeColors.dark() => const MueddaThemeColors(
        canvas: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        surfaceMuted: AppColors.darkSurfaceVariant,
        border: AppColors.darkBorder,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        textTertiary: Color(0xFF8F8F9C),
        shadow: Color(0x52000000),
      );

  @override
  MueddaThemeColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? shadow,
  }) {
    return MueddaThemeColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  MueddaThemeColors lerp(ThemeExtension<MueddaThemeColors>? other, double t) {
    if (other is! MueddaThemeColors) return this;
    return MueddaThemeColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension MueddaThemeContext on BuildContext {
  MueddaThemeColors get mueddaColors =>
      Theme.of(this).extension<MueddaThemeColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? MueddaThemeColors.dark()
          : MueddaThemeColors.light());
}
