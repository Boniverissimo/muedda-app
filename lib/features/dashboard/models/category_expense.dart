import '../../../core/database/app_database.dart';

class CategoryExpense {
  const CategoryExpense({required this.category, required this.totalCents});

  final Category category;
  final int totalCents;
}
