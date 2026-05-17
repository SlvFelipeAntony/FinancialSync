class CreditTransaction {
  final int? id;
  final String type;
  final String description;
  final double value;
  final String category;
  final String date;
  final int installment; // Total de parcelas (ex: 5)
  final int currentInstallment; // Parcela atual (ex: 1, 2, 3...)
  final int creditCardId;

  CreditTransaction({
    this.id,
    required this.type,
    required this.description,
    required this.value,
    required this.category,
    required this.date,
    required this.installment,
    this.currentInstallment = 1, // Por padrão é 1
    required this.creditCardId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'value': value,
      'category': category,
      'date': date,
      'installment': installment,
      'current_installment': currentInstallment,
      'credit_card_id': creditCardId,
    };
  }

  factory CreditTransaction.fromMap(Map<String, dynamic> map) {
    return CreditTransaction(
      id: map['id'],
      type: map['type'],
      description: map['description'],
      value: (map['value'] as num).toDouble(),
      category: map['category'],
      date: map['date'],
      installment: map['installment'],
      currentInstallment: map['current_installment'] ?? 1,
      creditCardId: map['credit_card_id'],
    );
  }
}