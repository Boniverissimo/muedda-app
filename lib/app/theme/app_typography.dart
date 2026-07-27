import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final foreground = brightness == Brightness.dark
        ? const Color(0xFFF7F7FA)
        : const Color(0xFF20202A);

    return GoogleFonts.interTextTheme().copyWith(
      displaySmall: GoogleFonts.inter(
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: foreground,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: foreground,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    );
  }
}
