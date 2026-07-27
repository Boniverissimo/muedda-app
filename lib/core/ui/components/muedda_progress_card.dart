import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import 'muedda_card.dart';

class MueddaProgressCard extends StatelessWidget {
  const MueddaProgressCard({
    required this.title,
    required this.value,
    super.key,
    this.subtitle,
    this.trailing,
    this.progressColor,
  });

  final String title;
  final String? subtitle;
  final double value;
  final Widget? trailing;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0.0, 1.0);
    final color = progressColor ??
        (normalized >= 1
            ? AppColors.expense
            : normalized >= .8
                ? AppColors.warning
                : AppColors.primary);
    return MueddaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 9,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}
