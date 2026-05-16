class AccountTransaction {
  final int? id;
  final String type; // 'entrada' ou 'saida'
  final String description;
  final double value;
  final String category;
  final String date;
  final String? time;
  final String? application;
  final String? link;
  final int accountsId;

  AccountTransaction({
    this.id,
    required this.type,
    required this.description,
    required this.value,
    required this.category,
    required this.date,
    this.time,
    this.application,
    this.link,
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
      'application': application,
      'link': link,
      'accounts_id': accountsId,
    };
  }

  factory AccountTransaction.fromMap(Map<String, dynamic> map) {
    return AccountTransaction(
      id: map['id'],
      type: map['type'],
      description: map['description'],
      value: map['value'],
      category: map['category'],
      date: map['date'],
      time: map['time'],
      application: map['application'],
      link: map['link'],
      accountsId: map['accounts_id'],
    );
  }
}