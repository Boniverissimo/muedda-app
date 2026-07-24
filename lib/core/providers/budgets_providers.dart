import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/budgets/models/category_budget.dart';
import '../repositories/budgets_repository.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository();
});

final budgetsControllerProvider =
    StateNotifierProvider<BudgetsController, AsyncValue<List<CategoryBudget>>>(
      (ref) => BudgetsController(ref.watch(budgetsRepositoryProvider)),
    );

class BudgetsController
    extends StateNotifier<AsyncValue<List<CategoryBudget>>> {
  BudgetsController(this._repository) : super(const AsyncLoading()) {
    load();
  }

  final BudgetsRepository _repository;

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.loadBudgets);
  }

  Future<void> save(CategoryBudget budget) async {
    final current = [...(state.asData?.value ?? const <CategoryBudget>[])];
    final index = current.indexWhere(
      (item) => item.categoryId == budget.categoryId,
    );

    if (index >= 0) {
      current[index] = budget;
    } else {
      current.add(budget);
    }

    current.sort((a, b) => a.categoryId.compareTo(b.categoryId));
    await _persist(current);
  }

  Future<void> remove(int categoryId) async {
    final current = [...(state.asData?.value ?? const <CategoryBudget>[])];
    current.removeWhere((item) => item.categoryId == categoryId);
    await _persist(current);
  }

  Future<void> toggle(CategoryBudget budget) async {
    await save(budget.copyWith(isActive: !budget.isActive));
  }

  Future<void> _persist(List<CategoryBudget> budgets) async {
    state = AsyncData(budgets);
    try {
      await _repository.saveBudgets(budgets);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
