import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/features/smart_entry/domain/services/transaction_text_parser.dart';

void main() {
  const parser = TransactionTextParser();
  final reference = DateTime(2026, 7, 24, 15, 30);

  test('interpreta despesa de mercado em reais', () {
    final result = parser.parse(
      'Paguei R\$ 89,90 no Assaí ontem',
      now: reference,
    );

    expect(result.type, 'expense');
    expect(result.amountCents, 8990);
    expect(result.suggestedCategoryName, 'Mercado');
    expect(result.occurredAt, DateTime(2026, 7, 23));
    expect(result.description, contains('Assaí'));
  });

  test('interpreta receita de salário', () {
    final result = parser.parse(
      'Recebi salário de 3.500,00 hoje',
      now: reference,
    );

    expect(result.type, 'income');
    expect(result.amountCents, 350000);
    expect(result.suggestedCategoryName, 'Salário');
    expect(result.occurredAt, DateTime(2026, 7, 24));
  });

  test('interpreta combustível', () {
    final result = parser.parse(
      'Gasolina 220 reais no posto Shell',
      now: reference,
    );

    expect(result.type, 'expense');
    expect(result.amountCents, 22000);
    expect(result.suggestedCategoryName, 'Combustível');
  });

  test('interpreta transferência', () {
    final result = parser.parse(
      'Transferi 500 da Caixa para Nubank',
      now: reference,
    );

    expect(result.type, 'transfer');
    expect(result.amountCents, 50000);
  });
}
