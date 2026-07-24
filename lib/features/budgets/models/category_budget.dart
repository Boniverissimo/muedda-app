class CategoryBudget {
  const CategoryBudget({
    required this.categoryId,
    required this.monthlyLimitCents,
    this.warningPercent = 80,
    this.isActive = true,
  });

  final int categoryId;
  final int monthlyLimitCents;
  final int warningPercent;
  final bool isActive;

  CategoryBudget copyWith({
    int? categoryId,
    int? monthlyLimitCents,
    int? warningPercent,
    bool? isActive,
  }) {
    return CategoryBudget(
      categoryId: categoryId ?? this.categoryId,
      monthlyLimitCents: monthlyLimitCents ?? this.monthlyLimitCents,
      warningPercent: warningPercent ?? this.warningPercent,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object> toJson() {
    return {
      'categoryId': categoryId,
      'monthlyLimitCents': monthlyLimitCents,
      'warningPercent': warningPercent,
      'isActive': isActive,
    };
  }

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    return CategoryBudget(
      categoryId: json['categoryId'] as int,
      monthlyLimitCents: json['monthlyLimitCents'] as int,
      warningPercent: (json['warningPercent'] as int?) ?? 80,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }
}
