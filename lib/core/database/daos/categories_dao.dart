import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Stream<List<Category>> watchAllCategories() {
    return (select(
      categories,
    )..orderBy([(table) => OrderingTerm.asc(table.name)])).watch();
  }

  Stream<List<Category>> watchCategoriesByType(String type) {
    return (select(categories)
          ..where((table) => table.type.equals(type))
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .watch();
  }

  Future<List<Category>> getAllCategories() {
    return (select(
      categories,
    )..orderBy([(table) => OrderingTerm.asc(table.name)])).get();
  }

  Future<Category?> getCategoryById(int id) {
    return (select(
      categories,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> createCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  Future<bool> updateCategory(Category category) {
    return update(categories).replace(category);
  }

  Future<int> updateCategoryById({
    required int id,
    String? name,
    String? type,
    String? iconName,
    String? colorHex,
    int? parentCategoryId,
    bool? isActive,
  }) {
    return (update(categories)..where((table) => table.id.equals(id))).write(
      CategoriesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        iconName: iconName != null ? Value(iconName) : const Value.absent(),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
        parentCategoryId: parentCategoryId != null
            ? Value(parentCategoryId)
            : const Value.absent(),
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
      ),
    );
  }

  Future<int> deactivateCategory(int id) {
    return (update(categories)..where((table) => table.id.equals(id))).write(
      const CategoriesCompanion(isActive: Value(false)),
    );
  }

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((table) => table.id.equals(id))).go();
  }
}
