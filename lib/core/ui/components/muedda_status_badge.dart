import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class MueddaStatusBadge extends StatelessWidget {
  const MueddaStatusBadge({
    required this.label,
    required this.type,
    super.key,
  });

  final String label;
  final MueddaStatusType type;

  @override
  Widget build(BuildContext context) {
    final palette = switch (type) {
      MueddaStatusType.success => (AppColors.incomeLight, AppColors.income),
      MueddaStatusType.danger => (AppColors.expenseLight, AppColors.expense),
      MueddaStatusType.warning => (AppColors.warningLight, AppColors.warning),
      MueddaStatusType.info => (AppColors.infoLight, AppColors.info),
      MueddaStatusType.neutral => (AppColors.surfaceVariant, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: palette.$2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum MueddaStatusType { success, danger, warning, info, neutral }
