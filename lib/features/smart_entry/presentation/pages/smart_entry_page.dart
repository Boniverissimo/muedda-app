import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/categories_providers.dart';
import '../../../transactions/presentation/pages/new_transaction_page.dart';
import '../../domain/models/parsed_transaction.dart';
import '../../domain/services/transaction_text_parser.dart';

class SmartEntryPage extends ConsumerStatefulWidget {
  const SmartEntryPage({super.key});

  @override
  ConsumerState<SmartEntryPage> createState() => _SmartEntryPageState();
}

class _SmartEntryPageState extends ConsumerState<SmartEntryPage> {
  final _controller = TextEditingController();
  final _parser = const TransactionTextParser();
  ParsedTransaction? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesStreamProvider).valueOrNull ?? const <Category>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Registro inteligente')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Conte o que aconteceu',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Exemplo: “Paguei R\$ 89,90 no Assaí ontem”. Você poderá revisar tudo antes de salvar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 4,
              maxLines: 7,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Descreva a movimentação...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onSubmitted: (_) => _interpret(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _interpret,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Interpretar'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openManual(),
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Preencher manualmente'),
            ),
            if (_result case final result?) ...[
              const SizedBox(height: 24),
              _ResultCard(
                result: result,
                category: _findCategory(categories, result),
                onContinue: result.hasMinimumData
                    ? () => _openForm(result, categories)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _interpret() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma movimentação para interpretar.'),
        ),
      );
      return;
    }
    setState(() => _result = _parser.parse(text));
  }

  Category? _findCategory(List<Category> categories, ParsedTransaction result) {
    final suggestion = result.suggestedCategoryName?.toLowerCase();
    if (suggestion == null) return null;

    final expectedType = result.type == 'income' ? 'income' : 'expense';
    final sameType = categories.where(
      (category) => category.type == expectedType,
    );

    for (final category in sameType) {
      final name = category.name.toLowerCase();
      if (name == suggestion ||
          name.contains(suggestion) ||
          suggestion.contains(name)) {
        return category;
      }
    }

    return null;
  }

  Future<void> _openForm(
    ParsedTransaction result,
    List<Category> categories,
  ) async {
    final category = _findCategory(categories, result);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => NewTransactionPage(
          initialType: result.type,
          initialDescription: result.description,
          initialAmountCents: result.amountCents,
          initialOccurredAt: result.occurredAt,
          initialCategoryId: category?.id,
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openManual() {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NewTransactionPage()));
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.category,
    required this.onContinue,
  });

  final ParsedTransaction result;
  final Category? category;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat('dd/MM/yyyy', 'pt_BR');
    final confidence = (result.confidence * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 8),
                Text(
                  'Interpretação',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text('$confidence%'),
              ],
            ),
            const Divider(height: 28),
            _ResultLine(label: 'Tipo', value: _typeLabel(result.type)),
            _ResultLine(
              label: 'Valor',
              value: result.amountCents == null
                  ? 'Não identificado'
                  : currency.format(result.amountCents! / 100),
            ),
            _ResultLine(
              label: 'Descrição',
              value: result.description ?? 'Não identificada',
            ),
            _ResultLine(label: 'Data', value: date.format(result.occurredAt)),
            _ResultLine(
              label: 'Categoria',
              value:
                  category?.name ??
                  result.suggestedCategoryName ??
                  'Sem sugestão',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: const Text('Continuar para salvar'),
              ),
            ),
            if (result.hasMinimumData) ...[
              const SizedBox(height: 8),
              Text(
                'Na próxima tela, escolha a conta e a categoria e toque em “Salvar transação”.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (!result.hasMinimumData) ...[
              const SizedBox(height: 8),
              const Text(
                'Não foi possível identificar valor e descrição. Ajuste o texto e tente novamente.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    return switch (type) {
      'income' => 'Receita',
      'transfer' => 'Transferência',
      'card' => 'Cartão',
      _ => 'Despesa',
    };
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
