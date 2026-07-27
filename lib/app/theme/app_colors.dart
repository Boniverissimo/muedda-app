import 'package:flutter/material.dart';

/// Paleta central do Muedda.
/// Mantém os nomes usados nas telas antigas e novas para evitar quebras.
abstract final class AppColors {
  static const Color primary = Color(0xFF6857E5);
  static const Color primaryDark = Color(0xFF4E3CC7);
  static const Color primaryLight = Color(0xFFEDEAFF);
  static const Color secondary = Color(0xFF8D7DF2);

  static const Color background = Color(0xFFF7F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F1F7);
  static const Color border = Color(0xFFE5E5EE);
  static const Color divider = Color(0xFFECECF2);

  static const Color textPrimary = Color(0xFF20202A);
  static const Color textSecondary = Color(0xFF666675);
  static const Color textTertiary = Color(0xFF9797A5);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color disabled = Color(0xFFB9B9C4);

  static const Color income = Color(0xFF1FAD79);
  static const Color incomeLight = Color(0xFFE4F7F0);
  static const Color expense = Color(0xFFE65C66);
  static const Color expenseLight = Color(0xFFFDEBED);
  static const Color warning = Color(0xFFE5A229);
  static const Color warningLight = Color(0xFFFFF5DD);
  static const Color info = Color(0xFF4285D4);
  static const Color infoLight = Color(0xFFE7F1FC);

  static const Color darkBackground = Color(0xFF111116);
  static const Color darkSurface = Color(0xFF1B1B22);
  static const Color darkSurfaceVariant = Color(0xFF25252E);
  static const Color darkBorder = Color(0xFF30303B);
  static const Color darkTextPrimary = Color(0xFFF7F7FA);
  static const Color darkTextSecondary = Color(0xFFB6B6C1);
}
