import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/muedda_theme_colors.dart';

class MueddaBottomNavigation extends StatelessWidget {
  const MueddaBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const items = <MueddaNavigationItemData>[
    MueddaNavigationItemData('Início', Icons.home_outlined, Icons.home_rounded),
    MueddaNavigationItemData('Lançamentos', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    MueddaNavigationItemData('Relatórios', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    MueddaNavigationItemData('Mais', Icons.grid_view_outlined, Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.mueddaColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(color: colors.shadow, blurRadius: 28, offset: const Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _item(0),
              _item(1),
              const SizedBox(width: 76),
              _item(2),
              _item(3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index) => Expanded(
        child: _MueddaNavigationItem(
          data: items[index],
          selected: selectedIndex == index,
          onTap: () => onDestinationSelected(index),
        ),
      );
}

class MueddaNavigationRail extends StatelessWidget {
  const MueddaNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAdd,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.mueddaColors;
    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                minimumSize: const Size(52, 52),
                maximumSize: const Size(52, 52),
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.transparent,
                groupAlignment: -0.55,
                destinations: [
                  for (final item in MueddaBottomNavigation.items)
                    NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MueddaNavigationItem extends StatelessWidget {
  const _MueddaNavigationItem({required this.data, required this.selected, required this.onTap});

  final MueddaNavigationItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mueddaColors;
    final color = selected ? AppColors.primary : colors.textTertiary;
    return Semantics(
      selected: selected,
      button: true,
      label: data.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: selected ? 40 : 32,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(selected ? data.selectedIcon : data.icon, size: 22, color: color),
                ),
                const SizedBox(height: 3),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 10.5, height: 1, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MueddaNavigationItemData {
  const MueddaNavigationItemData(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
