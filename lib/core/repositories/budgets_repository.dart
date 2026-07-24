import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/budgets/models/category_budget.dart';

class BudgetsRepository {
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, 'meu_financeiro_orcamentos.json'));
  }

  Future<List<CategoryBudget>> loadBudgets() async {
    final file = await _getFile();
    if (!await file.exists()) {
      return const <CategoryBudget>[];
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return const <CategoryBudget>[];
    }

    final decoded = jsonDecode(content) as List<dynamic>;
    return decoded
        .map((item) => CategoryBudget.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveBudgets(List<CategoryBudget> budgets) async {
    final file = await _getFile();
    await file.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(budgets.map((budget) => budget.toJson()).toList()),
      flush: true,
    );
  }
}
