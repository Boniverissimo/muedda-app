import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({
    required this.onAccounts,
    required this.onCards,
    required this.onBills,
    required this.onReports,
  });

  final VoidCallback onAccounts;
  final VoidCallback onCards;
  final VoidCallback onBills;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        'Contas',
        Icons.account_balance_rounded,
        AppColors.info,
        AppColors.infoLight,
        onAccounts,
      ),
      _ActionData(
        'Cartões',
        Icons.credit_card_rounded,
        AppColors.primary,
        AppColors.primaryLight,
        onCards,
      ),
      _ActionData(
        'Contas a pagar',
        Icons.receipt_long_rounded,
        AppColors.warning,
        AppColors.warningLight,
        onBills,
      ),
      _ActionData(
        'Relatórios',
        Icons.insert_chart_rounded,
        AppColors.income,
        AppColors.incomeLight,
        onReports,
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: actions.map((action) {
        return Expanded(
          child: InkWell(
            onTap: action.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: action.background,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(action.icon, color: action.color, size: 23),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionData {
  const _ActionData(
    this.label,
    this.icon,
    this.color,
    this.background,
    this.onTap,
  );

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
}
