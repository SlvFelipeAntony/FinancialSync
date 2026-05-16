class CreditCard {
  final int? id;
  final String name;
  final String lastDigits;
  final double limitValue;
  final String closingDate; // Dia do fechamento (ex: "05")
  final String expirationDate; // Dia do vencimento (ex: "12")
  final int accountId; // Conta vinculada para pagamento

  CreditCard({
    this.id,
    required this.name,
    required this.lastDigits,
    required this.limitValue,
    required this.closingDate,
    required this.expirationDate,
    required this.accountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastdigits': lastDigits,
      'limit_value': limitValue,
      'closingdate': closingDate,
      'expirationdate': expirationDate,
      'account_id': accountId,
    };
  }

  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'],
      name: map['name'],
      lastDigits: map['lastdigits'],
      limitValue: map['limit_value'],
      closingDate: map['closingdate'],
      expirationDate: map['expirationdate'],
      accountId: map['account_id'],
    );
  }
}