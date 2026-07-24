import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/category_expense.dart';

class CategoryExpensesCard extends StatelessWidget {
  const CategoryExpensesCard({super.key, required this.expenses});

  final List<CategoryExpense> expenses;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos por categoria',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (expenses.isEmpty)
              const Text('Nenhum gasto registrado neste mês.')
            else
              ...expenses.take(5).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.category.name)),
                      Text(
                        currencyFormatter.format(item.totalCents / 100),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
