class AccountTransaction {
  final int? id;
  final String type; // 'entrada' ou 'saida'
  final String description;
  final double value;
  final String category;
  final String date;
  final String? time;
  final int accountsId;

  AccountTransaction({
    this.id,
    required this.type,
    required this.description,
    required this.value,
    required this.category,
    required this.date,
    this.time,
    required this.accountsId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'value': value,
      'category': category,
      'date': date,
      'time': time,
      'accounts_id': accountsId,
    };
  }
}