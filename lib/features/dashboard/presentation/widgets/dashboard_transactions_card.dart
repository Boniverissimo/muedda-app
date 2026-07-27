import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/database/app_database.dart';
import 'dashboard_card_decoration.dart';
import 'dashboard_empty_card.dart';

class DashboardTransactionsCard extends StatelessWidget {
  const DashboardTransactionsCard({
    required this.entries,
    required this.showValues,
    required this.currency,
  });

  final List<LedgerEntry> entries;
  final bool showValues;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const DashboardEmptyCard(
        icon: Icons.receipt_long_outlined,
        title: 'Nenhuma movimentação',
        subtitle: 'Seus lançamentos recentes aparecerão aqui.',
      );
    }

    return Container(
      decoration: dashboardCardDecoration(),
      child: Column(
        children: List.generate(entries.length, (index) {
          final entry = entries[index];
          return Column(
            children: [
              _TransactionTile(
                entry: entry,
                showValues: showValues,
                currency: currency,
              ),
              if (index < entries.length - 1)
                const Divider(
                  height: 1,
                  indent: 68,
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

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.entry,
    required this.showValues,
    required this.currency,
  });

  final LedgerEntry entry;
  final bool showValues;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.type == 'income';
    final isTransfer = entry.type == 'transfer';
    final color = isIncome
        ? AppColors.income
        : isTransfer
        ? AppColors.info
        : AppColors.expense;
    final background = isIncome
        ? AppColors.incomeLight
        : isTransfer
        ? AppColors.infoLight
        : AppColors.expenseLight;
    final icon = isIncome
        ? Icons.south_west_rounded
        : isTransfer
        ? Icons.swap_horiz_rounded
        : Icons.north_east_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat(
                    "dd 'de' MMM • HH:mm",
                    'pt_BR',
                  ).format(entry.occurredAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            showValues
                ? '${isIncome
                      ? '+'
                      : isTransfer
                      ? ''
                      : '-'} ${currency.format(entry.amountCents / 100)}'
                : 'R\$ ••••',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
