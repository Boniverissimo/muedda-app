import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/accounts_providers.dart';
import '../../../../core/providers/ledger_entries_providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _showValues = true;

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(dashboardPeriodProvider);
    final allEntriesAsync = ref.watch(ledgerEntriesStreamProvider);
    final periodEntriesAsync = ref.watch(entriesByPeriodStreamProvider(period));
    final accountsAsync = ref.watch(accountsStreamProvider);

    final allEntries = allEntriesAsync.asData?.value ?? const <LedgerEntry>[];
    final periodEntries =
        periodEntriesAsync.asData?.value ?? const <LedgerEntry>[];
    final accounts = accountsAsync.asData?.value ?? const <Account>[];

    final paidEntries = allEntries.where((entry) => entry.isPaid).toList();
    final paidPeriodEntries = periodEntries
        .where((entry) => entry.isPaid)
        .toList();

    final patrimonyCents = _calculatePatrimony(accounts, paidEntries);
    final incomeCents = paidPeriodEntries
        .where((entry) => entry.type == 'income')
        .fold<int>(0, (total, entry) => total + entry.amountCents);
    final expenseCents = paidPeriodEntries
        .where((entry) => entry.type == 'expense')
        .fold<int>(0, (total, entry) => total + entry.amountCents);
    final investmentCents = _calculateInvestmentBalance(accounts, paidEntries);

    final recentEntries = [...allEntries]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final pendingEntries =
        allEntries
            .where((entry) => !entry.isPaid && entry.type != 'transfer')
            .toList()
          ..sort((a, b) {
            final first = a.dueDate ?? a.occurredAt;
            final second = b.dueDate ?? b.occurredAt;
            return first.compareTo(second);
          });

    final monthlyFlow = _buildMonthlyFlow(paidEntries);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(ledgerEntriesStreamProvider);
            ref.invalidate(accountsStreamProvider);
            await Future<void>.delayed(const Duration(milliseconds: 250));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                sliver: SliverList.list(
                  children: [
                    const _FigmaMobileHeader(),
                    const SizedBox(height: 14),
                    _HeroCard(
                      value: _money(patrimonyCents),
                      income: _money(incomeCents),
                      expense: _money(expenseCents),
                      showValues: _showValues,
                      onToggleVisibility: () {
                        setState(() => _showValues = !_showValues);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Saldo Disponível',
                            value: _money(patrimonyCents),
                            growth: '↑ 2,4% este mês',
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: AppColors.primary,
                            iconBackground: AppColors.primaryLight,
                            showValues: _showValues,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Investimentos',
                            value: _money(investmentCents),
                            growth: '↑ 7,8% este ano',
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.info,
                            iconBackground: AppColors.infoLight,
                            showValues: _showValues,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _CashFlowCard(
                      data: monthlyFlow,
                      showValues: _showValues,
                      onDetails: () => context.push(AppRouter.reports),
                    ),
                    const SizedBox(height: 14),
                    _AiInsightCard(
                      incomeCents: incomeCents,
                      expenseCents: expenseCents,
                    ),
                    const SizedBox(height: 14),
                    _TransactionsCard(
                      entries: recentEntries.take(5).toList(),
                      showValues: _showValues,
                      currency: _currency,
                      onSeeAll: () => context.push(AppRouter.reports),
                    ),
                    const SizedBox(height: 14),
                    _UpcomingBillsCard(
                      entries: pendingEntries.take(3).toList(),
                      showValues: _showValues,
                      currency: _currency,
                      onSeeAll: () =>
                          context.push(AppRouter.payablesReceivables),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _money(int amountCents) => _currency.format(amountCents / 100);

  int _calculatePatrimony(
    List<Account> accounts,
    List<LedgerEntry> paidEntries,
  ) {
    var total = accounts.fold<int>(
      0,
      (sum, account) => sum + account.initialBalanceCents,
    );

    for (final entry in paidEntries) {
      if (entry.type == 'income') total += entry.amountCents;
      if (entry.type == 'expense') total -= entry.amountCents;

      if (entry.type == 'transfer') {
        total -= entry.amountCents;
        if (entry.destinationAccountId != null) total += entry.amountCents;
      }
    }

    return total;
  }

  int _calculateInvestmentBalance(
    List<Account> accounts,
    List<LedgerEntry> paidEntries,
  ) {
    final investmentAccounts = accounts.where((account) {
      final name = account.name.toLowerCase();
      return name.contains('invest') ||
          name.contains('corretora') ||
          name.contains('reserva');
    }).toList();

    if (investmentAccounts.isEmpty) return 0;

    final ids = investmentAccounts.map((account) => account.id).toSet();
    var total = investmentAccounts.fold<int>(
      0,
      (sum, account) => sum + account.initialBalanceCents,
    );

    for (final entry in paidEntries) {
      if (entry.type == 'income' && ids.contains(entry.accountId)) {
        total += entry.amountCents;
      }
      if (entry.type == 'expense' && ids.contains(entry.accountId)) {
        total -= entry.amountCents;
      }
      if (entry.type == 'transfer') {
        if (ids.contains(entry.accountId)) total -= entry.amountCents;
        if (ids.contains(entry.destinationAccountId)) {
          total += entry.amountCents;
        }
      }
    }

    return total;
  }

  List<_MonthFlow> _buildMonthlyFlow(List<LedgerEntry> entries) {
    final now = DateTime.now();

    return List.generate(6, (index) {
      final date = DateTime(now.year, now.month - 5 + index);
      final matching = entries.where(
        (entry) =>
            entry.occurredAt.year == date.year &&
            entry.occurredAt.month == date.month,
      );

      final income = matching
          .where((entry) => entry.type == 'income')
          .fold<int>(0, (sum, entry) => sum + entry.amountCents);
      final expense = matching
          .where((entry) => entry.type == 'expense')
          .fold<int>(0, (sum, entry) => sum + entry.amountCents);

      return _MonthFlow(
        label: DateFormat.MMM('pt_BR').format(date).replaceAll('.', ''),
        income: income,
        expense: expense,
      );
    });
  }
}

class _FigmaMobileHeader extends StatelessWidget {
  const _FigmaMobileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 15,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Início',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _HeaderButton(icon: Icons.dark_mode_outlined, onTap: () {}),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _HeaderButton(icon: Icons.notifications_none_rounded, onTap: () {}),
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.expense,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.value,
    required this.income,
    required this.expense,
    required this.showValues,
    required this.onToggleVisibility,
  });

  final String value;
  final String income;
  final String expense;
  final bool showValues;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF4930E8), Color(0xFF7C5DF9), Color(0xFF9F6BF8)],
          stops: [0, 0.6, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x305B3DF5),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -52,
            right: -52,
            child: _Bubble(size: 176, opacity: 0.06),
          ),
          Positioned(
            top: 32,
            right: -22,
            child: _Bubble(size: 96, opacity: 0.06),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Patrimônio Total',
                        style: TextStyle(
                          color: Color(0xBFFFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Material(
                      color: const Color(0x26FFFFFF),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onToggleVisibility,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            showValues
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    showValues ? value : 'R\$ •••.•••,••',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroInnerMetric(
                        label: 'Receitas jul.',
                        value: showValues ? income : '••••',
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroInnerMetric(
                        label: 'Despesas jul.',
                        value: showValues ? expense : '••••',
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeroInnerMetric extends StatelessWidget {
  const _HeroInnerMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x21FFFFFF),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xA6FFFFFF)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xA6FFFFFF),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.growth,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.showValues,
  });

  final String title;
  final String value;
  final String growth;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool showValues;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            showValues ? value : '•••••',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            growth,
            style: const TextStyle(
              color: AppColors.income,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({
    required this.data,
    required this.showValues,
    required this.onDetails,
  });

  final List<_MonthFlow> data;
  final bool showValues;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionHeader(
            title: 'Fluxo de Caixa',
            action: 'Detalhes',
            onAction: onDetails,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 156,
            child: CustomPaint(
              painter: _CashFlowPainter(data: data),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data
                .map(
                  (item) => Expanded(
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 11),
          const Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Receitas'),
              SizedBox(width: 20),
              _LegendDot(color: AppColors.expense, label: 'Despesas'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashFlowPainter extends CustomPainter {
  _CashFlowPainter({required this.data});

  final List<_MonthFlow> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.fold<double>(1, (maxValue, item) {
      return math.max(
        maxValue,
        math.max(item.income.toDouble(), item.expense.toDouble()),
      );
    });

    final chartRect = Rect.fromLTWH(0, 8, size.width, size.height - 18);
    final step = data.length == 1 ? 0.0 : chartRect.width / (data.length - 1);

    Path pathFor(int Function(_MonthFlow) getter) {
      final path = Path();

      for (var index = 0; index < data.length; index++) {
        final x = chartRect.left + step * index;
        final value = getter(data[index]).toDouble();
        final normalized = value / maxValue;
        final y = chartRect.bottom - normalized * chartRect.height * 0.86;

        if (index == 0) {
          path.moveTo(x, y);
        } else {
          final previousX = chartRect.left + step * (index - 1);
          final controlX = (previousX + x) / 2;
          final previousValue = getter(data[index - 1]).toDouble();
          final previousY =
              chartRect.bottom -
              (previousValue / maxValue) * chartRect.height * 0.86;
          path.cubicTo(controlX, previousY, controlX, y, x, y);
        }
      }

      return path;
    }

    final incomePath = pathFor((item) => item.income);
    final expensePath = pathFor((item) => item.expense);

    final incomeFill = Path.from(incomePath)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();

    final expenseFill = Path.from(expensePath)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();

    canvas.drawPath(
      incomeFill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x445B3DF5), Color(0x005B3DF5)],
        ).createShader(chartRect),
    );

    canvas.drawPath(
      expenseFill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33FF5252), Color(0x00FF5252)],
        ).createShader(chartRect),
    );

    canvas.drawPath(
      incomePath,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      expensePath,
      Paint()
        ..color = AppColors.expense
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CashFlowPainter oldDelegate) {
    return oldDelegate.data != data;
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({required this.incomeCents, required this.expenseCents});

  final int incomeCents;
  final int expenseCents;

  @override
  Widget build(BuildContext context) {
    final difference = incomeCents - expenseCents;
    final healthy = difference >= 0;
    final message = healthy
        ? 'Ótimo controle! Seu saldo do período está saudável. '
              'Você manteve as receitas acima das despesas.'
        : 'Suas despesas estão acima das receitas neste período. '
              'Revise os maiores gastos para recuperar o equilíbrio.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x305B3DF5), width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insight do Muedda IA',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.45,
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

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({
    required this.entries,
    required this.showValues,
    required this.currency,
    required this.onSeeAll,
  });

  final List<LedgerEntry> entries;
  final bool showValues;
  final NumberFormat currency;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionHeader(
            title: 'Últimas Transações',
            action: 'Ver todas',
            onAction: onSeeAll,
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'Nenhuma transação encontrada.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...List.generate(entries.length, (index) {
              final entry = entries[index];
              final income = entry.type == 'income';
              final transfer = entry.type == 'transfer';
              final color = transfer
                  ? AppColors.info
                  : income
                  ? AppColors.income
                  : AppColors.expense;
              final icon = transfer
                  ? Icons.swap_horiz_rounded
                  : income
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index > 0)
                    const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, size: 17, color: color),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                transfer
                                    ? 'Transferência'
                                    : income
                                    ? 'Receita'
                                    : 'Despesa',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              showValues
                                  ? '${income
                                            ? '+'
                                            : transfer
                                            ? ''
                                            : '−'}'
                                        '${currency.format(entry.amountCents / 100)}'
                                  : 'R\$ ••••',
                              style: TextStyle(
                                color: income
                                    ? AppColors.income
                                    : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat(
                                'dd MMM',
                                'pt_BR',
                              ).format(entry.occurredAt),
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _UpcomingBillsCard extends StatelessWidget {
  const _UpcomingBillsCard({
    required this.entries,
    required this.showValues,
    required this.currency,
    required this.onSeeAll,
  });

  final List<LedgerEntry> entries;
  final bool showValues;
  final NumberFormat currency;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionHeader(
            title: 'Próximas Contas',
            action: 'Ver todas',
            onAction: onSeeAll,
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Text(
                'Nenhuma conta pendente.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ...entries.map((entry) {
              final dueDate = entry.dueDate ?? entry.occurredAt;
              final days = dueDate.difference(DateTime.now()).inDays;
              final color = days <= 3
                  ? AppColors.expense
                  : days <= 7
                  ? AppColors.warning
                  : AppColors.info;

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                            'Vence em ${DateFormat('dd/MM', 'pt_BR').format(dueDate)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      showValues
                          ? currency.format(entry.amountCents / 100)
                          : 'R\$ ••••',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MonthFlow {
  const _MonthFlow({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final int income;
  final int expense;
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(color: Color(0x0A0F172A), blurRadius: 18, offset: Offset(0, 7)),
    ],
  );
}
