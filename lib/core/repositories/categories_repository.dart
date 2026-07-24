import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/categories_dao.dart';

class CategoriesRepository {
  CategoriesRepository(this._categoriesDao);

  final CategoriesDao _categoriesDao;

  Stream<List<Category>> watchAllCategories() {
    return _categoriesDao.watchAllCategories();
  }

  Stream<List<Category>> watchCategoriesByType(String type) {
    return _categoriesDao.watchCategoriesByType(type);
  }

  Future<List<Category>> getAllCategories() {
    return _categoriesDao.getAllCategories();
  }

  Future<Category?> getCategoryById(int id) {
    return _categoriesDao.getCategoryById(id);
  }

  Future<int> createCategory({
    required String name,
    required String type,
    String? iconName,
    String? colorHex,
    int? parentCategoryId,
  }) {
    return _categoriesDao.createCategory(
      CategoriesCompanion.insert(
        name: name,
        type: type,
        iconName: Value(iconName),
        colorHex: Value(colorHex),
        parentCategoryId: Value(parentCategoryId),
      ),
    );
  }

  Future<int> updateCategory({
    required int id,
    String? name,
    String? type,
    String? iconName,
    String? colorHex,
    int? parentCategoryId,
    bool? isActive,
  }) {
    return _categoriesDao.updateCategoryById(
      id: id,
      name: name,
      type: type,
      iconName: iconName,
      colorHex: colorHex,
      parentCategoryId: parentCategoryId,
      isActive: isActive,
    );
  }

  Future<int> deactivateCategory(int id) {
    return _categoriesDao.deactivateCategory(id);
  }

  Future<int> deleteCategory(int id) {
    return _categoriesDao.deleteCategory(id);
  }

  Future<void> createDefaultCategoriesIfNeeded() async {
    final categories = await getAllCategories();

    if (categories.isNotEmpty) return;

    final defaults = [
      ('Alimentação', 'expense'),
      ('Transporte', 'expense'),
      ('Moradia', 'expense'),
      ('Contas', 'expense'),
      ('Saúde', 'expense'),
      ('Educação', 'expense'),
      ('Lazer', 'expense'),
      ('Compras', 'expense'),
      ('Assinaturas', 'expense'),
      ('Salário', 'income'),
      ('Freelance', 'income'),
      ('Investimentos', 'income'),
      ('Presentes', 'income'),
      ('Reembolsos', 'income'),
    ];

    for (final category in defaults) {
      await createCategory(name: category.$1, type: category.$2);
    }
  }
}
