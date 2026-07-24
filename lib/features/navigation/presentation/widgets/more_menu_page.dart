import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreMenuPage extends StatelessWidget {
  const MoreMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Contas'),
                  subtitle: const Text('Gerencie suas contas e saldos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/accounts');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Categorias'),
                  subtitle: const Text('Organize receitas e despesas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/categories');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.credit_card_outlined),
                  title: const Text('Cartões'),
                  subtitle: const Text('Gerencie cartões de crédito'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/credit-cards');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_note_outlined),
                  title: const Text('Contas a pagar e receber'),
                  subtitle: const Text('Acompanhe vencimentos e pendências'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/payables-receivables');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_repeat_outlined),
                  title: const Text('Recorrências'),
                  subtitle: const Text('Gerencie lançamentos repetitivos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/recurring-transactions');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: const Text('Orçamentos'),
                  subtitle: const Text('Defina limites mensais por categoria'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/budgets');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Configurações'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Configurações serão implementadas em breve.',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sobre o aplicativo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Meu App Financeiro',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
