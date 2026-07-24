import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../repositories/categories_repository.dart';
import 'database_providers.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return CategoriesRepository(database.categoriesDao);
});

final categoriesStreamProvider = StreamProvider.autoDispose<List<Category>>((
  ref,
) {
  final repository = ref.watch(categoriesRepositoryProvider);

  return repository.watchAllCategories();
});

final incomeCategoriesStreamProvider =
    StreamProvider.autoDispose<List<Category>>((ref) {
      final repository = ref.watch(categoriesRepositoryProvider);

      return repository.watchCategoriesByType('income');
    });

final expenseCategoriesStreamProvider =
    StreamProvider.autoDispose<List<Category>>((ref) {
      final repository = ref.watch(categoriesRepositoryProvider);

      return repository.watchCategoriesByType('expense');
    });
final categoriesInitializationProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(categoriesRepositoryProvider);

  await repository.createDefaultCategoriesIfNeeded();
});
