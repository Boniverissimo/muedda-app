import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'muedda_colors.dart';

abstract final class MueddaTypography {
  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 32,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: MueddaColors.textPrimary,
  );

  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: MueddaColors.textPrimary,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: MueddaColors.textPrimary,
  );

  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: MueddaColors.textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: MueddaColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: MueddaColors.textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: MueddaColors.textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: MueddaColors.textSecondary,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: MueddaColors.textPrimary,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: MueddaColors.textSecondary,
  );
}
