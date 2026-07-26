class ParsedTransaction {
  const ParsedTransaction({
    required this.originalText,
    required this.type,
    required this.occurredAt,
    required this.confidence,
    this.description,
    this.amountCents,
    this.suggestedCategoryName,
  });

  final String originalText;
  final String type;
  final String? description;
  final int? amountCents;
  final DateTime occurredAt;
  final String? suggestedCategoryName;
  final double confidence;

  bool get hasMinimumData {
    return amountCents != null &&
        amountCents! > 0 &&
        description != null &&
        description!.trim().isNotEmpty;
  }
}
