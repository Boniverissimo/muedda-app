import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class MueddaIconButton extends StatelessWidget {
  const MueddaIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.isPrimary = false,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isPrimary;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = isPrimary
        ? AppColors.primary
        : dark
            ? AppColors.darkSurfaceVariant
            : AppColors.surfaceVariant;
    final foreground = isPrimary
        ? Colors.white
        : dark
            ? AppColors.darkTextPrimary
            : AppColors.textPrimary;

    final button = SizedBox.square(
      dimension: size,
      child: IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 21),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
