import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'dashboard_card_decoration.dart';

class DashboardPatrimonyCard extends StatelessWidget {
  const DashboardPatrimonyCard({
    super.key,
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

  static const _gradientStart = Color(0xFF5B3DF5);
  static const _gradientEnd = Color(0xFF7C5CFF);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: 'Resumo do patrimônio',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [_gradientStart, _gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D5B3DF5),
              blurRadius: 32,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -48,
              top: -78,
              child: _DecorativeCircle(size: 196, opacity: 0.09),
            ),
            const Positioned(
              left: -76,
              bottom: -118,
              child: _DecorativeCircle(size: 238, opacity: 0.06),
            ),
            Positioned(
              right: 18,
              bottom: 28,
              child: Transform.rotate(
                angle: -0.18,
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 92,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Patrimônio total',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _VisibilityButton(
                        showValues: showValues,
                        onPressed: onToggleVisibility,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      showValues ? value : 'R\$ ••••••',
                      key: ValueKey(showValues),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 15,
                          color: Color(0xFFCBFFD6),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '12,8% este mês',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 330;

                      if (compact) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HeroMetric(
                              label: 'Receitas',
                              value: showValues ? income : 'R\$ ••••',
                              icon: Icons.south_west_rounded,
                              iconColor: const Color(0xFFCBFFD6),
                            ),
                            const SizedBox(height: 14),
                            _HeroMetric(
                              label: 'Despesas',
                              value: showValues ? expense : 'R\$ ••••',
                              icon: Icons.north_east_rounded,
                              iconColor: const Color(0xFFFFD4D4),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _HeroMetric(
                              label: 'Receitas',
                              value: showValues ? income : 'R\$ ••••',
                              icon: Icons.south_west_rounded,
                              iconColor: const Color(0xFFCBFFD6),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 42,
                            margin: const EdgeInsets.symmetric(horizontal: 18),
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          Expanded(
                            child: _HeroMetric(
                              label: 'Despesas',
                              value: showValues ? expense : 'R\$ ••••',
                              icon: Icons.north_east_rounded,
                              iconColor: const Color(0xFFFFD4D4),
                            ),
                          ),
                        ],
                      );
                    },
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

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.showValues, required this.onPressed});

  final bool showValues;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: showValues ? 'Ocultar valores' : 'Mostrar valores',
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              showValues
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.showValues,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool showValues;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: dashboardCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                color: AppColors.textTertiary.withValues(alpha: 0.75),
                size: 17,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              showValues ? value : 'R\$ ••••',
              key: ValueKey(showValues),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
