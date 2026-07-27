import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/database/app_database.dart';
import 'dashboard_card_decoration.dart';
import 'dashboard_empty_card.dart';

class DashboardUpcomingBillsCard extends StatelessWidget {
  const DashboardUpcomingBillsCard({
    required this.entries,
    required this.showValues,
    required this.currency,
    required this.onTap,
  });

  final List<LedgerEntry> entries;
  final bool showValues;
  final NumberFormat currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const DashboardEmptyCard(
        icon: Icons.event_available_rounded,
        title: 'Tudo em dia',
        subtitle: 'Você não possui contas pendentes neste período.',
      );
    }

    return Container(
      decoration: dashboardCardDecoration(),
      child: Column(
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          final dueDate = entry.dueDate ?? entry.occurredAt;
          return Column(
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(20))
                    : index == entries.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(20))
                    : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat.MMM('pt_BR')
                                  .format(dueDate)
                                  .replaceAll('.', '')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              DateFormat.d().format(dueDate),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        showValues
                            ? currency.format(entry.amountCents / 100)
                            : 'R\$ ••••',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 19,
                        color: AppColors.disabled,
                      ),
                    ],
                  ),
                ),
              ),
              if (index < entries.length - 1)
                const Divider(
                  height: 1,
                  indent: 70,
                  endIndent: 16,
                  color: AppColors.divider,
                ),
            ],
          );
        }),
      ),
    );
  }
}
