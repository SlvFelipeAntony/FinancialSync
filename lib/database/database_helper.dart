import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../models/credit_card_model.dart';
import '../models/credit_transaction_model.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';

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
      // IMPORTANTE: Ativa as chaves estrangeiras
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabela de Usuários
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Tabela de Contas
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

    // Transações de Conta
    await db.execute('''
      CREATE TABLE account_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        value REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT,
        application TEXT,  -- Coluna adicionada
        link TEXT,         -- Coluna adicionada
        accounts_id INTEGER NOT NULL,
        FOREIGN KEY (accounts_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    // Cartões de Crédito (Adicionado conforme seu SQL)
    await db.execute('''
      CREATE TABLE credit_card (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        lastdigits TEXT NOT NULL,
        limit_value REAL NOT NULL,
        closingdate TEXT NOT NULL,
        expirationdate TEXT NOT NULL,
        account_id INTEGER NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    // Transações de Cartão de Crédito (Adicionado conforme seu SQL)
    await db.execute('''
      CREATE TABLE credit_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        value REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        installment INTEGER NOT NULL,
        credit_card_id INTEGER NOT NULL,
        FOREIGN KEY (credit_card_id) REFERENCES credit_card (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Categorias
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Inserir categorias padrão para o usuário não começar do zero
    List<String> defaultCategories = [
      'Alimentação', 'Transporte', 'Lazer', 'Saúde', 'Educação', 'Moradia', 'Salário'
    ];

    for (String cat in defaultCategories) {
      await db.insert('categories', {'name': cat});
    }
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
      // 1. Regista a transação
      await txn.insert('account_transactions', trans.toMap());

      // 2. Procura o saldo atual da conta
      final accountQuery = await txn.query(
          'accounts',
          where: 'id = ?',
          whereArgs: [trans.accountsId]
      );

      if (accountQuery.isNotEmpty) {
        // Converte em 'num' primeiro para evitar erros se o SQLite devolver um 'int'
        double currentBalance = (accountQuery.first['balance'] as num).toDouble();

        // Calcula o ajuste
        double adjustment = trans.type == 'entrada' ? trans.value : -trans.value;
        double newBalance = currentBalance + adjustment;

        // 3. Atualiza a conta com o valor exato calculado
        await txn.update(
          'accounts',
          {'balance': newBalance},
          where: 'id = ?',
          whereArgs: [trans.accountsId],
        );
      }
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

  Future<double> getTotalBalance() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(balance) as total FROM accounts');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalIncome() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT SUM(value) as total FROM account_transactions WHERE type = 'entrada'");
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalExpense() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT SUM(value) as total FROM account_transactions WHERE type = 'saida'");
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getDashboardSummary() async {
    return {
      'balance': await getTotalBalance(),
      'income': await getTotalIncome(),
      'expense': await getTotalExpense(),
    };
  }

  Future<User?> getUser(int id) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUserProfile(int id, String name, String email) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'name': name, 'email': email},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updatePassword(int id, String newPassword) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD DE CATEGORIAS ---

  Future<int> createCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name COLLATE NOCASE ASC');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

