enum TransactionType {
  expense,
  income,
}

enum TransactionCategory {
  irrigation,
  fertilizer,
  pesticide,
  sales,
  other,
}

class FinancialTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String description;
  final DateTime date;
  final String? cropId;  // Pour lier la transaction à une culture spécifique

  FinancialTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.cropId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.toString(),
      'category': category.toString(),
      'description': description,
      'date': date.toIso8601String(),
      'cropId': cropId,
    };
  }

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'],
      amount: json['amount'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
      ),
      description: json['description'],
      date: DateTime.parse(json['date']),
      cropId: json['cropId'],
    );
  }
} 