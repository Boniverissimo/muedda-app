import '../../models/account_balance.dart';
import '../widgets/accounts_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/ledger_entries_providers.dart';
import '../../../../core/providers/accounts_providers.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/providers/categories_providers.dart';
import '../../models/category_expense.dart';
import '../widgets/category_expenses_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _showValues = true;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final period = ref.watch(dashboardPeriodProvider);
    final selectedPeriod = ref.watch(dashboardPeriodTypeProvider);

    final allEntriesAsync = ref.watch(ledgerEntriesStreamProvider);
    final periodEntriesAsync = ref.watch(entriesByPeriodStreamProvider(period));
    final accountsAsync = ref.watch(accountsStreamProvider);
    final expenseCategoriesAsync = ref.watch(expenseCategoriesStreamProvider);

    final allEntries = allEntriesAsync.asData?.value ?? const <LedgerEntry>[];
    final periodEntries =
        periodEntriesAsync.asData?.value ?? const <LedgerEntry>[];
    final accounts = accountsAsync.asData?.value ?? const <Account>[];
    final expenseCategories =
        expenseCategoriesAsync.asData?.value ?? const <Category>[];

    final paidEntries = allEntries.where((entry) => entry.isPaid);
    final paidPeriodEntries = periodEntries.where((entry) => entry.isPaid);
    final accountBalances = accounts.map((account) {
      var balanceCents = account.initialBalanceCents;

      for (final entry in paidEntries) {
        if (entry.type == 'income' && entry.accountId == account.id) {
          balanceCents += entry.amountCents;
        }

        if (entry.type == 'expense' && entry.accountId == account.id) {
          balanceCents -= entry.amountCents;
        }

        if (entry.type == 'transfer') {
          if (entry.accountId == account.id) {
            balanceCents -= entry.amountCents;
          }

          if (entry.destinationAccountId == account.id) {
            balanceCents += entry.amountCents;
          }
        }
      }

      return AccountBalance(account: account, balanceCents: balanceCents);
    }).toList();

    final balanceCents = paidEntries.fold<int>(0, (total, entry) {
      switch (entry.type) {
        case 'income':
          return total + entry.amountCents;
        case 'expense':
          return total - entry.amountCents;
        default:
          return total;
      }
    });

    final incomeCents = paidPeriodEntries
        .where((entry) => entry.type == 'income')
        .fold<int>(0, (total, entry) => total + entry.amountCents);

    final expenseCents = paidPeriodEntries
        .where((entry) => entry.type == 'expense')
        .fold<int>(0, (total, entry) => total + entry.amountCents);

    // 👇 COLE AQUI
    final expensesByCategory =
        expenseCategories
            .map((category) {
              final totalCents = paidPeriodEntries
                  .where(
                    (entry) =>
                        entry.type == 'expense' &&
                        entry.categoryId == category.id,
                  )
                  .fold<int>(0, (total, entry) => total + entry.amountCents);

              return CategoryExpense(
                category: category,
                totalCents: totalCents,
              );
            })
            .where((item) => item.totalCents > 0)
            .toList()
          ..sort(
            (first, second) => second.totalCents.compareTo(first.totalCents),
          );

    final pendingEntries = allEntries.where(
      (entry) => !entry.isPaid && entry.type != 'transfer',
    );
    final pendingIncomeCents = pendingEntries
        .where((entry) => entry.type == 'income')
        .fold<int>(0, (total, entry) => total + entry.amountCents);
    final pendingExpenseCents = pendingEntries
        .where((entry) => entry.type == 'expense')
        .fold<int>(0, (total, entry) => total + entry.amountCents);
    final projectedBalanceCents =
        balanceCents + pendingIncomeCents - pendingExpenseCents;

    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));
    final overdueEntries = pendingEntries.where((entry) {
      final dueDate = entry.dueDate ?? entry.occurredAt;
      return dueDate.isBefore(today);
    }).toList();
    final overdueCents = overdueEntries.fold<int>(
      0,
      (total, entry) => total + entry.amountCents,
    );
    final upcomingEntries =
        pendingEntries.where((entry) {
          final dueDate = entry.dueDate ?? entry.occurredAt;
          return !dueDate.isBefore(today) && dueDate.isBefore(nextWeek);
        }).toList()..sort((a, b) {
          final aDate = a.dueDate ?? a.occurredAt;
          final bDate = b.dueDate ?? b.occurredAt;
          return aDate.compareTo(bDate);
        });

    final monthlyFlow = List.generate(6, (index) {
      final monthDate = DateTime(now.year, now.month - (5 - index));
      final monthEntries = allEntries.where((entry) {
        return entry.isPaid &&
            entry.occurredAt.year == monthDate.year &&
            entry.occurredAt.month == monthDate.month;
      });
      final income = monthEntries
          .where((entry) => entry.type == 'income')
          .fold<int>(0, (total, entry) => total + entry.amountCents);
      final expense = monthEntries
          .where((entry) => entry.type == 'expense')
          .fold<int>(0, (total, entry) => total + entry.amountCents);
      return _MonthlyFlow(
        month: monthDate,
        incomeCents: income,
        expenseCents: expense,
      );
    });

    final recentEntries = allEntries.take(3).toList();

    final isLoading =
        allEntriesAsync.isLoading ||
        periodEntriesAsync.isLoading ||
        accountsAsync.isLoading ||
        expenseCategoriesAsync.isLoading;

    final hasError =
        allEntriesAsync.hasError ||
        periodEntriesAsync.hasError ||
        accountsAsync.hasError ||
        expenseCategoriesAsync.hasError;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          context.push(AppRouter.smartEntry);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ledgerEntriesStreamProvider);
            ref.invalidate(entriesByPeriodStreamProvider(period));
            ref.invalidate(accountsStreamProvider);
            ref.invalidate(expenseCategoriesStreamProvider);

            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              160,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, now),
                const SizedBox(height: AppSpacing.lg),
                _buildPeriodSelector(context, selectedPeriod: selectedPeriod),
                const SizedBox(height: AppSpacing.lg),
                if (hasError)
                  _buildErrorCard(context)
                else ...[
                  _buildBalanceCard(
                    context,
                    balanceCents: balanceCents,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildIncomeExpenseCards(
                    context,
                    incomeCents: incomeCents,
                    expenseCents: expenseCents,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AccountsCard(
                    accounts: accountBalances,
                    isLoading: isLoading,
                    showValues: _showValues,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _buildForecastSection(
                  context,
                  projectedBalanceCents: projectedBalanceCents,
                  pendingIncomeCents: pendingIncomeCents,
                  pendingExpenseCents: pendingExpenseCents,
                  overdueCents: overdueCents,
                  overdueCount: overdueEntries.length,
                  isLoading: isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildCashFlowSection(context, monthlyFlow: monthlyFlow),
                const SizedBox(height: AppSpacing.lg),
                _buildUpcomingSection(context, entries: upcomingEntries),
                const SizedBox(height: AppSpacing.lg),
                _buildQuickActions(context),
                const SizedBox(height: AppSpacing.lg),
                _buildCategoriesSection(context, expensesByCategory),
                const SizedBox(height: AppSpacing.lg),
                _buildTransactionsSection(
                  context,
                  entries: recentEntries,
                  isLoading: isLoading,
                  hasError: hasError,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DateTime date) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, Jailton',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatMonthYear(date),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _HeaderButton(icon: Icons.notifications_none_rounded, onPressed: () {}),
        const SizedBox(width: AppSpacing.sm),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            'JV',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context, {
    required DashboardPeriodType selectedPeriod,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<DashboardPeriodType>(
        segments: const [
          ButtonSegment<DashboardPeriodType>(
            value: DashboardPeriodType.today,
            label: Text('Hoje'),
          ),
          ButtonSegment<DashboardPeriodType>(
            value: DashboardPeriodType.week,
            label: Text('Semana'),
          ),
          ButtonSegment<DashboardPeriodType>(
            value: DashboardPeriodType.month,
            label: Text('Mês'),
          ),
          ButtonSegment<DashboardPeriodType>(
            value: DashboardPeriodType.year,
            label: Text('Ano'),
          ),
        ],
        selected: {selectedPeriod},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          ref.read(dashboardPeriodTypeProvider.notifier).state =
              selection.first;
        },
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context, {
    required int balanceCents,
    required bool isLoading,
  }) {
    String displayedValue;

    if (isLoading) {
      displayedValue = 'Carregando...';
    } else if (_showValues) {
      displayedValue = _formatCurrency(balanceCents);
    } else {
      displayedValue = 'R\$ ••••••';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Saldo disponível',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: _showValues ? 'Ocultar valores' : 'Mostrar valores',
                onPressed: () {
                  setState(() {
                    _showValues = !_showValues;
                  });
                },
                icon: Icon(
                  _showValues
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            displayedValue,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Saldo calculado com lançamentos pagos',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseCards(
    BuildContext context, {
    required int incomeCents,
    required int expenseCents,
    required bool isLoading,
  }) {
    final incomeValue = _buildDisplayedValue(
      amountCents: incomeCents,
      isLoading: isLoading,
    );

    final expenseValue = _buildDisplayedValue(
      amountCents: expenseCents,
      isLoading: isLoading,
    );

    return Row(
      children: [
        Expanded(
          child: _FinancialSummaryCard(
            title: 'Receitas',
            value: incomeValue,
            icon: Icons.south_west_rounded,
            color: AppColors.income,
            backgroundColor: AppColors.incomeLight,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _FinancialSummaryCard(
            title: 'Despesas',
            value: expenseValue,
            icon: Icons.north_east_rounded,
            color: AppColors.expense,
            backgroundColor: AppColors.expenseLight,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastSection(
    BuildContext context, {
    required int projectedBalanceCents,
    required int pendingIncomeCents,
    required int pendingExpenseCents,
    required int overdueCents,
    required int overdueCount,
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Visão prevista',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRouter.payablesReceivables),
              child: const Text('Ver vencimentos'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DashboardCard(
          child: Column(
            children: [
              _ForecastRow(
                icon: Icons.account_balance_outlined,
                title: 'Saldo previsto',
                value: _buildDisplayedValue(
                  amountCents: projectedBalanceCents,
                  isLoading: isLoading,
                ),
                color: projectedBalanceCents >= 0
                    ? AppColors.income
                    : AppColors.expense,
              ),
              const Divider(height: AppSpacing.lg),
              _ForecastRow(
                icon: Icons.call_received_rounded,
                title: 'A receber',
                value: _buildDisplayedValue(
                  amountCents: pendingIncomeCents,
                  isLoading: isLoading,
                ),
                color: AppColors.income,
              ),
              const SizedBox(height: AppSpacing.md),
              _ForecastRow(
                icon: Icons.call_made_rounded,
                title: 'A pagar',
                value: _buildDisplayedValue(
                  amountCents: pendingExpenseCents,
                  isLoading: isLoading,
                ),
                color: AppColors.expense,
              ),
              if (overdueCount > 0) ...[
                const SizedBox(height: AppSpacing.md),
                _ForecastRow(
                  icon: Icons.warning_amber_rounded,
                  title:
                      '$overdueCount vencimento${overdueCount == 1 ? '' : 's'} '
                      'atrasado${overdueCount == 1 ? '' : 's'}',
                  value: _buildDisplayedValue(
                    amountCents: overdueCents,
                    isLoading: isLoading,
                  ),
                  color: AppColors.warning,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowSection(
    BuildContext context, {
    required List<_MonthlyFlow> monthlyFlow,
  }) {
    final maximum = monthlyFlow.fold<int>(0, (current, item) {
      final itemMaximum = item.incomeCents > item.expenseCents
          ? item.incomeCents
          : item.expenseCents;
      return itemMaximum > current ? itemMaximum : current;
    });

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fluxo dos últimos 6 meses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const _ChartLegend(color: AppColors.income, label: 'Receitas'),
              const SizedBox(width: AppSpacing.sm),
              const _ChartLegend(color: AppColors.expense, label: 'Despesas'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyFlow.map((item) {
                final incomeFactor = maximum == 0
                    ? 0.0
                    : item.incomeCents / maximum;
                final expenseFactor = maximum == 0
                    ? 0.0
                    : item.expenseCents / maximum;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FlowBar(
                                factor: incomeFactor,
                                color: AppColors.income,
                                tooltip: _formatCurrency(item.incomeCents),
                              ),
                              const SizedBox(width: 3),
                              _FlowBar(
                                factor: expenseFactor,
                                color: AppColors.expense,
                                tooltip: _formatCurrency(item.expenseCents),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _shortMonth(item.month.month),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection(
    BuildContext context, {
    required List<LedgerEntry> entries,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Próximos 7 dias',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRouter.payablesReceivables),
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (entries.isEmpty)
          _DashboardCard(
            child: Row(
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.income,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Nenhum vencimento previsto para os próximos 7 dias.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          _DashboardCard(
            child: Column(
              children: entries.take(5).map((entry) {
                final dueDate = entry.dueDate ?? entry.occurredAt;
                final color = entry.type == 'income'
                    ? AppColors.income
                    : AppColors.expense;
                final isLast = entry == entries.take(5).last;
                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(
                          entry.type == 'income'
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
                          color: color,
                        ),
                      ),
                      title: Text(
                        entry.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_formatDueDate(dueDate)),
                      trailing: Text(
                        _showValues
                            ? _formatCurrency(entry.amountCents)
                            : 'R\$ ••••',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    if (!isLast) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    final difference = due.difference(today).inDays;
    if (difference == 0) return 'Vence hoje';
    if (difference == 1) return 'Vence amanhã';
    return 'Vence em $difference dias • '
        "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}";
  }

  String _shortMonth(int month) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return months[month - 1];
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acesso rápido',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Contas',
                color: AppColors.info,
                backgroundColor: AppColors.infoLight,
                onTap: () => context.push(AppRouter.accounts),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickAction(
                icon: Icons.credit_card_outlined,
                label: 'Cartões',
                color: AppColors.chartPurple,
                backgroundColor: const Color(0xFFF0EBFB),
                onTap: () => context.push(AppRouter.creditCards),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickAction(
                icon: Icons.flag_outlined,
                label: 'Vencimentos',
                color: AppColors.warning,
                backgroundColor: AppColors.warningLight,
                onTap: () => context.push(AppRouter.payablesReceivables),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickAction(
                icon: Icons.category_outlined,
                label: 'Categorias',
                color: AppColors.secondary,
                backgroundColor: AppColors.secondaryLight,
                onTap: () => context.push(AppRouter.categories),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.savings_outlined,
                label: 'Orçamentos',
                color: AppColors.income,
                backgroundColor: AppColors.incomeLight,
                onTap: () => context.push(AppRouter.budgets),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickAction(
                icon: Icons.bar_chart_outlined,
                label: 'Relatórios',
                color: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
                onTap: () => context.push(AppRouter.reports),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: SizedBox()),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    List<CategoryExpense> expensesByCategory,
  ) {
    return _DashboardCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gastos por categoria',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRouter.reports),
                child: const Text('Ver relatório'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CategoryExpensesCard(expenses: expensesByCategory),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(
    BuildContext context, {
    required List<LedgerEntry> entries,
    required bool isLoading,
    required bool hasError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Últimas transações',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRouter.payablesReceivables),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isLoading)
          const _DashboardCard(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hasError)
          _DashboardCard(
            child: Text(
              'Não foi possível carregar as últimas transações.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          )
        else if (entries.isEmpty)
          _DashboardCard(
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 42,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nenhum lançamento cadastrado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Cadastre uma receita ou despesa para começar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...entries.map((entry) {
            final appearance = _getEntryAppearance(entry);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _TransactionItem(
                title: entry.description,
                category: _buildEntrySubtitle(entry),
                value: _formatTransactionValue(entry),
                icon: appearance.icon,
                iconColor: appearance.color,
                iconBackground: appearance.color.withValues(alpha: 0.12),
                valueColor: appearance.color,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return _DashboardCard(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: AppColors.expense,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Não foi possível carregar os dados',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Puxe a tela para baixo para tentar novamente.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _buildDisplayedValue({
    required int amountCents,
    required bool isLoading,
  }) {
    if (isLoading) {
      return 'Carregando...';
    }

    if (!_showValues) {
      return 'R\$ ••••';
    }

    return _formatCurrency(amountCents);
  }

  String _formatCurrency(int amountCents) {
    final isNegative = amountCents < 0;
    final absoluteCents = amountCents.abs();
    final amount = absoluteCents / 100;

    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );

    final prefix = isNegative ? '- ' : '';

    return '${prefix}R\$ $formattedInteger,$decimalPart';
  }

  String _formatTransactionValue(LedgerEntry entry) {
    if (!_showValues) {
      return 'R\$ ••••';
    }

    final value = _formatCurrency(entry.amountCents);

    switch (entry.type) {
      case 'income':
        return '+ $value';
      case 'expense':
        return '- $value';
      default:
        return value;
    }
  }

  String _buildEntrySubtitle(LedgerEntry entry) {
    final typeLabel = switch (entry.type) {
      'income' => 'Receita',
      'expense' => 'Despesa',
      'transfer' => 'Transferência',
      _ => 'Lançamento',
    };

    final dateLabel = _formatEntryDate(entry.occurredAt);

    if (!entry.isPaid) {
      return '$typeLabel • $dateLabel • Pendente';
    }

    return '$typeLabel • $dateLabel';
  }

  String _formatEntryDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(entryDate).inDays;

    if (difference == 0) {
      return 'Hoje';
    }

    if (difference == 1) {
      return 'Ontem';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatMonthYear(DateTime date) {
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

    return '${months[date.month - 1]} de ${date.year}';
  }

  _EntryAppearance _getEntryAppearance(LedgerEntry entry) {
    switch (entry.type) {
      case 'income':
        return const _EntryAppearance(
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.income,
        );
      case 'transfer':
        return const _EntryAppearance(
          icon: Icons.swap_horiz_rounded,
          color: AppColors.info,
        );
      default:
        return const _EntryAppearance(
          icon: Icons.shopping_bag_outlined,
          color: AppColors.expense,
        );
    }
  }
}

class _MonthlyFlow {
  const _MonthlyFlow({
    required this.month,
    required this.incomeCents,
    required this.expenseCents,
  });

  final DateTime month;
  final int incomeCents;
  final int expenseCents;
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _FlowBar extends StatelessWidget {
  const _FlowBar({
    required this.factor,
    required this.color,
    required this.tooltip,
  });

  final double factor;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 10,
          height: factor == 0 ? 3.0 : 110.0 * factor.clamp(0.0, 1.0).toDouble(),
          decoration: BoxDecoration(
            color: factor == 0 ? AppColors.divider : color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _EntryAppearance {
  const _EntryAppearance({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  const _FinancialSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.title,
    required this.category,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.valueColor,
  });

  final String title;
  final String category;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
