import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import 'muedda_card.dart';

class MueddaMetricCard extends StatelessWidget {
  const MueddaMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
    this.caption,
    this.positive,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;
  final bool? positive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = positive == null
        ? AppColors.primary
        : positive!
            ? AppColors.income
            : AppColors.expense;

    return MueddaCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: accent),
                ),
              ),
              const Spacer(),
              if (caption != null)
                Flexible(
                  child: Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
