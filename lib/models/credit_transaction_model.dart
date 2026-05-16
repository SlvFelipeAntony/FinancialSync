class CreditTransaction {
  final int? id;
  final String description;
  final double value;
  final String category;
  final String date;
  final int installment; // Para o requisito RF07 (Parcelamentos)
  final int creditCardId;

  CreditTransaction({
    this.id,
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
      'type': 'saida', // Transações de cartão são sempre saídas na fatura
      'description': description,
      'value': value,
      'category': category,
      'date': date,
      'installment': installment,
      'credit_card_id': creditCardId,
    };
  }
}