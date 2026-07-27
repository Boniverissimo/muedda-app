import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/providers/ledger_entries_providers.dart';

class DashboardPeriodSelector extends StatelessWidget {
  const DashboardPeriodSelector({
    required this.selectedPeriod,
    required this.onSelected,
  });

  final DashboardPeriodType selectedPeriod;
  final ValueChanged<DashboardPeriodType> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = [
      (DashboardPeriodType.today, 'Hoje'),
      (DashboardPeriodType.week, 'Semana'),
      (DashboardPeriodType.month, 'Mês'),
      (DashboardPeriodType.year, 'Ano'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: options.map((option) {
          final selected = selectedPeriod == option.$1;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(option.$1),
              borderRadius: BorderRadius.circular(11),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x100F172A),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  option.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
