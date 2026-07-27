import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/muedda_theme_colors.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../transactions/presentation/pages/transactions_page.dart' as transactions;
import '../widgets/more_menu_page.dart';
import '../widgets/muedda_bottom_navigation.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = const [
    DashboardPage(),
    transactions.TransactionsPage(),
    ReportsPage(),
    MoreMenuPage(),
  ];

  void _changePage(int index) {
    if (_selectedIndex != index) setState(() => _selectedIndex = index);
  }

  void _openNewTransaction() => context.push(AppRouter.newTransaction);

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    final colors = context.mueddaColors;
    final content = IndexedStack(
      index: _selectedIndex,
      children: List.generate(
        _pages.length,
        (index) => HeroMode(
          enabled: index == _selectedIndex,
          child: TickerMode(enabled: index == _selectedIndex, child: _pages[index]),
        ),
      ),
    );

    if (desktop) {
      return Scaffold(
        backgroundColor: colors.canvas,
        body: Row(
          children: [
            MueddaNavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _changePage,
              onAdd: _openNewTransaction,
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.canvas,
      extendBody: true,
      body: content,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _MueddaFab(onPressed: _openNewTransaction),
      bottomNavigationBar: MueddaBottomNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _changePage,
      ),
    );
  }
}

class _MueddaFab extends StatelessWidget {
  const _MueddaFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.mueddaColors;
    return Semantics(
      button: true,
      label: 'Adicionar lançamento',
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
          border: Border.all(color: colors.surface, width: 5),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onPressed, child: const Icon(Icons.add_rounded, color: Colors.white, size: 32)),
        ),
      ),
    );
  }
}
