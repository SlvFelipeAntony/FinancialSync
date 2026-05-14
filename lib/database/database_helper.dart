import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/credit_card_model.dart';
import '../models/credit_transaction_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('financial_sync.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabelas baseadas no arquivo sqlite.sql
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        CHECK (type IN ('corrente', 'poupanca', 'investimento', 'carteira'))
      )
    ''');

    await db.execute('''
      CREATE TABLE account_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        value REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT,
        accounts_id INTEGER NOT NULL,
        FOREIGN KEY (accounts_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    // Adicionar tabelas credit_card e credit_transactions conforme o SQL
  }

  // Exemplo de CRUD para Contas (RF02)
  Future<int> createAccount(Account account) async {
    final db = await instance.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> readAllAccounts(int userId) async {
    final db = await instance.database;
    final result = await db.query('accounts', where: 'user_id = ?', whereArgs: [userId]);
    return result.map((json) => Account.fromMap(json)).toList();
  }

  Future<void> insertTransaction(AccountTransaction trans) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      // 1. Insere a transação
      await txn.insert('account_transactions', trans.toMap());

      // 2. Atualiza o saldo na tabela 'accounts'
      final double adjustment = trans.type == 'entrada' ? trans.value : -trans.value;
      await txn.rawUpdate(
        'UPDATE accounts SET balance = balance + ? WHERE id = ?',
        [adjustment, trans.accountsId],
      );
    });
  }

  Future<int> updateAccount(Account account) async {
    final db = await instance.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getFilteredTransactions(String? type) async {
    final db = await instance.database;

    if (type == null || type == 'todos') {
      return await db.rawQuery('''
      SELECT t.*, a.name as account_name 
      FROM account_transactions t 
      JOIN accounts a ON t.accounts_id = a.id 
      ORDER BY t.date DESC
    ''');
    } else {
      return await db.rawQuery('''
      SELECT t.*, a.name as account_name 
      FROM account_transactions t 
      JOIN accounts a ON t.accounts_id = a.id 
      WHERE t.type = ? 
      ORDER BY t.date DESC
    ''', [type]);
    }
  }

  Future<int> createCreditCard(CreditCard card) async {
    final db = await instance.database;
    return await db.insert('credit_card', card.toMap());
  }

  Future<List<CreditCard>> readAllCreditCards() async {
    final db = await instance.database;
    final result = await db.query('credit_card');
    return result.map((json) => CreditCard.fromMap(json)).toList();
  }

  Future<int> deleteCreditCard(int id) async {
    final db = await instance.database;
    return await db.delete('credit_card', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertCreditTransaction(CreditTransaction trans) async {
    final db = await instance.database;
    return await db.insert('credit_transactions', trans.toMap());
  }

  Future<List<Map<String, dynamic>>> getInvoiceTransactions(int cardId) async {
    final db = await instance.database;
    return await db.query(
      'credit_transactions',
      where: 'credit_card_id = ?',
      whereArgs: [cardId],
      orderBy: 'date DESC',
    );
  }

  Future<double> getInvoiceTotal(int cardId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT SUM(value) as total FROM credit_transactions WHERE credit_card_id = ?',
        [cardId]
    );
    return result.first['total'] != null ? result.first['total'] as double : 0.0;
  }

  Future<int> createUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> login(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }
}

