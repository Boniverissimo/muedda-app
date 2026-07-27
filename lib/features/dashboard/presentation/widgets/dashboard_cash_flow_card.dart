import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'dashboard_card_decoration.dart';
import 'dashboard_models.dart';

class DashboardCashFlowCard extends StatelessWidget {
  const DashboardCashFlowCard({
    required this.data,
    required this.showValues,
    required this.onReports,
  });

  final List<DashboardMonthFlow> data;
  final bool showValues;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(1, (current, item) {
      return math.max(current, math.max(item.income, item.expense));
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: dashboardCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fluxo de caixa',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Receitas e despesas nos últimos 6 meses',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onReports,
                icon: const Icon(Icons.more_horiz_rounded),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Receitas'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.expense, label: 'Despesas'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 155,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final incomeHeight = item.income <= 0
                    ? 4.0
                    : 112 * item.income / maxValue;
                final expenseHeight = item.expense <= 0
                    ? 4.0
                    : 112 * item.expense / maxValue;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 8,
                              height: incomeHeight,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 8,
                              height: expenseHeight,
                              decoration: BoxDecoration(
                                color: AppColors.expense.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          if (!showValues) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
