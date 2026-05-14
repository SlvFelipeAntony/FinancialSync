class Account {
  final int? id;
  final String name;
  final String type;
  final double balance;
  final int userId;

  Account({this.id, required this.name, required this.type, required this.balance, required this.userId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'user_id': userId,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      balance: map['balance'],
      userId: map['user_id'],
    );
  }
}