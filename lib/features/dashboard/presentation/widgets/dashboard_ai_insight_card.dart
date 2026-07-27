import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'dashboard_card_decoration.dart';

class DashboardAiInsightCard extends StatelessWidget {
  const DashboardAiInsightCard({
    required this.incomeCents,
    required this.expenseCents,
    required this.onTap,
  });

  final int incomeCents;
  final int expenseCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = incomeCents <= 0 ? 0.0 : expenseCents / incomeCents;
    final message = ratio > 0.85
        ? 'Suas despesas estão próximas das receitas. Revise os maiores gastos.'
        : ratio > 0.6
        ? 'Você está no caminho certo. Ainda há espaço para aumentar sua reserva.'
        : 'Ótimo controle! Seu saldo do período está saudável.';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF0EDFF), Color(0xFFF8F7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDCD4FF)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Muedda IA',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
