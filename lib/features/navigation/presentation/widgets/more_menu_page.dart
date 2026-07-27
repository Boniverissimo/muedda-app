import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class MoreMenuPage extends StatelessWidget {
  const MoreMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            120,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel('Organização financeira'),
            const SizedBox(height: AppSpacing.sm),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Contas',
                  subtitle: 'Saldos e instituições',
                  onTap: () => context.push('/accounts'),
                ),
                _MenuItem(
                  icon: Icons.category_outlined,
                  title: 'Categorias',
                  subtitle: 'Organize receitas e despesas',
                  onTap: () => context.push('/categories'),
                ),
                _MenuItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Cartões',
                  subtitle: 'Limites, faturas e compras',
                  onTap: () => context.push('/credit-cards'),
                ),
                _MenuItem(
                  icon: Icons.savings_outlined,
                  title: 'Orçamentos',
                  subtitle: 'Limites mensais por categoria',
                  onTap: () => context.push('/budgets'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel('Automação e planejamento'),
            const SizedBox(height: AppSpacing.sm),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.event_note_outlined,
                  title: 'A pagar e receber',
                  subtitle: 'Vencimentos e pendências',
                  onTap: () => context.push('/payables-receivables'),
                ),
                _MenuItem(
                  icon: Icons.event_repeat_outlined,
                  title: 'Recorrências',
                  subtitle: 'Lançamentos automáticos',
                  onTap: () => context.push('/recurring-transactions'),
                ),
                _MenuItem(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Entrada inteligente',
                  subtitle: 'Registre usando uma frase',
                  onTap: () => context.push('/smart-entry'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel('Aplicativo'),
            const SizedBox(height: AppSpacing.sm),
            _MenuCard(
              items: [
                _MenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Configurações',
                  subtitle: 'Preferências e aparência',
                  onTap: () => _showComingSoon(context),
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Sobre o Muedda',
                  subtitle: 'Versão e informações',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Muedda',
                    applicationVersion: '1.0.0',
                    applicationIcon: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.payments_outlined, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 30),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu espaço financeiro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Organize e personalize o Muedda',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações avançadas chegam na próxima versão.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            items[index],
            if (index != items.length - 1)
              const Divider(height: 1, indent: 72, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
