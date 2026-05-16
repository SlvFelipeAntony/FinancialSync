class CreditTransaction {
  final int? id;
  final String type;
  final String description;
  final double value;
  final String category;
  final String date;
  final int installment;
  final int creditCardId;

  CreditTransaction({
    this.id,
    this.type = 'saida',
    required this.description,
    required this.value,
    required this.category,
    required this.date,
    required this.installment,
    required this.creditCardId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type, // saída e entrada (estorno)
      'description': description,
      'value': value,
      'category': category,
      'date': date,
      'installment': installment,
      'credit_card_id': creditCardId,
    };
  }

  factory CreditTransaction.fromMap(Map<String, dynamic> map) {
    return CreditTransaction(
      id: map['id'],
      type: map['type'],
      description: map['description'],
      value: map['value'],
      category: map['category'],
      date: map['date'],
      installment: map['installment'],
      creditCardId: map['credit_card_id'],
    );
  }
}