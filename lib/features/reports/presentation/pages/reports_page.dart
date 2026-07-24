import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/accounts_providers.dart';
import '../../../../core/providers/categories_providers.dart';
import '../../../../core/providers/ledger_entries_providers.dart';
import '../../../../core/services/report_export_service.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final period = LedgerEntriesPeriod(
      start: _selectedMonth,
      end: DateTime(_selectedMonth.year, _selectedMonth.month + 1),
    );

    final entriesAsync = ref.watch(entriesByPeriodStreamProvider(period));

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: entriesAsync.when(
        data: (entries) {
          return _buildReport(entries, period);
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return _ErrorView(
            message: error.toString(),
            onRetry: () {
              ref.invalidate(entriesByPeriodStreamProvider(period));
            },
          );
        },
      ),
    );
  }

  Widget _buildReport(List<LedgerEntry> entries, LedgerEntriesPeriod period) {
    final completedEntries = entries.where((entry) => entry.isPaid).toList();

    final incomeEntries = completedEntries
        .where((entry) => entry.type == 'income')
        .toList();

    final expenseEntries = completedEntries
        .where((entry) => entry.type == 'expense')
        .toList();

    final pendingEntries = entries.where((entry) => !entry.isPaid).toList();

    final incomeCents = _sumEntries(incomeEntries);
    final expenseCents = _sumEntries(expenseEntries);
    final pendingCents = _sumEntries(pendingEntries);

    final balanceCents = incomeCents - expenseCents;

    final accounts =
        ref.watch(accountsStreamProvider).asData?.value ?? const <Account>[];
    final categories =
        ref.watch(categoriesStreamProvider).asData?.value ?? const <Category>[];

    final dailyData = _buildDailyData(entries);
    final largestExpenses = [
      ...expenseEntries,
    ]..sort((first, second) => second.amountCents.compareTo(first.amountCents));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(entriesByPeriodStreamProvider(period));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          40,
        ),
        children: [
          _MonthSelector(
            selectedMonth: _selectedMonth,
            onPrevious: _goToPreviousMonth,
            onNext: _canGoToNextMonth ? _goToNextMonth : null,
            onCurrentMonth: _goToCurrentMonth,
          ),
          const SizedBox(height: AppSpacing.lg),
          _FinancialSummary(
            incomeCents: incomeCents,
            expenseCents: expenseCents,
            balanceCents: balanceCents,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ReportSection(
            title: 'Exportar relatório',
            subtitle:
                'Os arquivos serão salvos em Documentos/Meu App Financeiro/Relatórios.',
            child: _ExportActions(
              isExporting: _isExporting,
              onExportPdf: () => _exportReport(
                format: _ReportExportFormat.pdf,
                entries: entries,
                period: period,
                accounts: accounts,
                categories: categories,
              ),
              onExportCsv: () => _exportReport(
                format: _ReportExportFormat.csv,
                entries: entries,
                period: period,
                accounts: accounts,
                categories: categories,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ReportSection(
            title: 'Visão geral',
            child: _OverviewGrid(
              entriesCount: entries.length,
              completedCount: completedEntries.length,
              pendingCount: pendingEntries.length,
              pendingCents: pendingCents,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ReportSection(
            title: 'Receitas e despesas por dia',
            subtitle: 'Movimentações concluídas no mês selecionado.',
            child: dailyData.isEmpty
                ? const _SectionEmptyState(
                    icon: Icons.bar_chart_outlined,
                    message: 'Ainda não há dados para exibir.',
                  )
                : _DailyMovementChart(data: dailyData),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ReportSection(
            title: 'Maiores despesas',
            subtitle: 'Os maiores gastos concluídos do período.',
            child: largestExpenses.isEmpty
                ? const _SectionEmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'Nenhuma despesa registrada neste mês.',
                  )
                : Column(
                    children: largestExpenses
                        .take(5)
                        .map(
                          (entry) => _ExpenseItem(
                            entry: entry,
                            totalExpenseCents: expenseCents,
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ReportSection(
            title: 'Distribuição das movimentações',
            child: _MovementDistribution(
              incomeCount: incomeEntries.length,
              expenseCount: expenseEntries.length,
              transferCount: completedEntries
                  .where((entry) => entry.type == 'transfer')
                  .length,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport({
    required _ReportExportFormat format,
    required List<LedgerEntry> entries,
    required LedgerEntriesPeriod period,
    required List<Account> accounts,
    required List<Category> categories,
  }) async {
    if (_isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final service = ReportExportService();
      final reportEnd = period.end.subtract(const Duration(microseconds: 1));

      final file = switch (format) {
        _ReportExportFormat.pdf => await service.exportPdf(
          start: period.start,
          end: reportEnd,
          entries: entries,
          accounts: accounts,
          categories: categories,
        ),
        _ReportExportFormat.csv => await service.exportCsv(
          start: period.start,
          end: reportEnd,
          entries: entries,
          accounts: accounts,
          categories: categories,
        ),
      };

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Relatório salvo em: ${file.path}'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível exportar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  bool get _canGoToNextMonth {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return _selectedMonth.isBefore(currentMonth);
  }

  void _goToPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    if (!_canGoToNextMonth) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  void _goToCurrentMonth() {
    final now = DateTime.now();

    setState(() {
      _selectedMonth = DateTime(now.year, now.month);
    });
  }

  int _sumEntries(List<LedgerEntry> entries) {
    return entries.fold<int>(0, (total, entry) => total + entry.amountCents);
  }

  List<_DailyReportData> _buildDailyData(List<LedgerEntry> entries) {
    final grouped = <int, _MutableDailyData>{};

    for (final entry in entries) {
      if (!entry.isPaid || entry.type == 'transfer') {
        continue;
      }

      final day = entry.occurredAt.day;

      final data = grouped.putIfAbsent(day, _MutableDailyData.new);

      if (entry.type == 'income') {
        data.incomeCents += entry.amountCents;
      } else if (entry.type == 'expense') {
        data.expenseCents += entry.amountCents;
      }
    }

    final result = grouped.entries
        .map(
          (entry) => _DailyReportData(
            day: entry.key,
            incomeCents: entry.value.incomeCents,
            expenseCents: entry.value.expenseCents,
          ),
        )
        .toList();

    result.sort((first, second) => first.day.compareTo(second.day));

    return result;
  }
}

enum _ReportExportFormat { pdf, csv }

class _ExportActions extends StatelessWidget {
  const _ExportActions({
    required this.isExporting,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  final bool isExporting;
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isExporting) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: isExporting ? null : onExportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Exportar PDF'),
            ),
            OutlinedButton.icon(
              onPressed: isExporting ? null : onExportCsv,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Exportar CSV'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrentMonth,
  });

  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onCurrentMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onCurrentMonth,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  children: [
                    Text(
                      _monthName(selectedMonth.month),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      selectedMonth.year.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return months[month - 1];
  }
}

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({
    required this.incomeCents,
    required this.expenseCents,
    required this.balanceCents,
  });

  final int incomeCents;
  final int expenseCents;
  final int balanceCents;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Receitas',
                value: _formatCurrency(incomeCents),
                icon: Icons.south_west_rounded,
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SummaryCard(
                title: 'Despesas',
                value: _formatCurrency(expenseCents),
                icon: Icons.north_east_rounded,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _balanceColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: _balanceColor(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resultado do mês',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(balanceCents),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _balanceColor(),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                balanceCents >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: _balanceColor(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _balanceColor() {
    return balanceCents >= 0 ? AppColors.income : AppColors.expense;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({
    required this.entriesCount,
    required this.completedCount,
    required this.pendingCount,
    required this.pendingCents,
  });

  final int entriesCount;
  final int completedCount;
  final int pendingCount;
  final int pendingCents;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.7,
      children: [
        _OverviewItem(
          title: 'Lançamentos',
          value: entriesCount.toString(),
          icon: Icons.receipt_long_outlined,
        ),
        _OverviewItem(
          title: 'Concluídos',
          value: completedCount.toString(),
          icon: Icons.check_circle_outline_rounded,
        ),
        _OverviewItem(
          title: 'Pendentes',
          value: pendingCount.toString(),
          icon: Icons.schedule_rounded,
        ),
        _OverviewItem(
          title: 'Valor pendente',
          value: _formatCurrency(pendingCents),
          icon: Icons.pending_actions_outlined,
        ),
      ],
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _DailyMovementChart extends StatelessWidget {
  const _DailyMovementChart({required this.data});

  final List<_DailyReportData> data;

  @override
  Widget build(BuildContext context) {
    final largestValue = data.fold<int>(0, (largest, item) {
      return math.max(largest, math.max(item.incomeCents, item.expenseCents));
    });

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, _) {
          return const SizedBox(width: AppSpacing.sm);
        },
        itemBuilder: (context, index) {
          final item = data[index];

          return SizedBox(
            width: 48,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _ChartBar(
                          value: item.incomeCents,
                          largestValue: largestValue,
                          color: AppColors.income,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _ChartBar(
                          value: item.expenseCents,
                          largestValue: largestValue,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.day.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({
    required this.value,
    required this.largestValue,
    required this.color,
  });

  final int value;
  final int largestValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final factor = largestValue == 0 ? 0.0 : value / largestValue;

    return Tooltip(
      message: _formatCurrency(value),
      child: FractionallySizedBox(
        heightFactor: factor.clamp(0.04, 1.0),
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: value == 0 ? color.withValues(alpha: 0.15) : color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  const _ExpenseItem({required this.entry, required this.totalExpenseCents});

  final LedgerEntry entry;
  final int totalExpenseCents;

  @override
  Widget build(BuildContext context) {
    final percentage = totalExpenseCents == 0
        ? 0.0
        : entry.amountCents / totalExpenseCents;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.north_east_rounded,
                  color: AppColors.expense,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(entry.occurredAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatCurrency(entry.amountCents),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.expense.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementDistribution extends StatelessWidget {
  const _MovementDistribution({
    required this.incomeCount,
    required this.expenseCount,
    required this.transferCount,
  });

  final int incomeCount;
  final int expenseCount;
  final int transferCount;

  @override
  Widget build(BuildContext context) {
    final total = incomeCount + expenseCount + transferCount;

    return Column(
      children: [
        _DistributionItem(
          label: 'Receitas',
          count: incomeCount,
          total: total,
          color: AppColors.income,
        ),
        const SizedBox(height: AppSpacing.md),
        _DistributionItem(
          label: 'Despesas',
          count: expenseCount,
          total: total,
          color: AppColors.expense,
        ),
        const SizedBox(height: AppSpacing.md),
        _DistributionItem(
          label: 'Transferências',
          count: transferCount,
          total: total,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _DistributionItem extends StatelessWidget {
  const _DistributionItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : count / total;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              '$count',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 42,
              child: Text(
                '${(percentage * 100).round()}%',
                textAlign: TextAlign.end,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Não foi possível carregar os relatórios.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyReportData {
  const _DailyReportData({
    required this.day,
    required this.incomeCents,
    required this.expenseCents,
  });

  final int day;
  final int incomeCents;
  final int expenseCents;
}

class _MutableDailyData {
  int incomeCents = 0;
  int expenseCents = 0;
}

String _formatCurrency(int cents) {
  final isNegative = cents < 0;
  final value = cents.abs() / 100;
  final parts = value.toStringAsFixed(2).split('.');

  final integerPart = parts.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );

  final formatted = 'R\$ $integerPart,${parts.last}';

  return isNegative ? '- $formatted' : formatted;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
