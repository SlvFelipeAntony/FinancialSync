import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
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
        current_installment INTEGER DEFAULT 1,
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

  Future<void> insertCreditTransaction(CreditTransaction trans) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      // --- LÓGICA DE CENTAVOS E PARCELAS ---
      int totalCents = (trans.value * 100).round();
      int baseCents = totalCents ~/ trans.installment;
      int remainderCents = totalCents % trans.installment;

      DateTime originalDate = DateTime.parse(trans.date);

      for (int i = 1; i <= trans.installment; i++) {
        // A primeira parcela absorve os centavos restantes para fechar a conta perfeita
        double instValue = (i == 1) ? (baseCents + remainderCents) / 100.0 : baseCents / 100.0;

        // Calcula o mês correto
        int totalMonths = originalDate.month - 1 + (i - 1);
        int targetYear = originalDate.year + (totalMonths ~/ 12);
        int targetMonth = (totalMonths % 12) + 1;
        int targetDay = originalDate.day;

        // Garante que não pule para o mês seguinte (ex: 31 de Fev vira 28 de Fev)
        int daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        if (targetDay > daysInMonth) targetDay = daysInMonth;

        String instDate = "${targetYear.toString()}-${targetMonth.toString().padLeft(2, '0')}-${targetDay.toString().padLeft(2, '0')}";

        Map<String, dynamic> map = trans.toMap();
        map['value'] = instValue;
        map['date'] = instDate;
        map['current_installment'] = i;
        map.remove('id');

        await txn.insert('credit_transactions', map);
      }

      // --- ATUALIZAÇÃO DO LIMITE DO CARTÃO (O TOTAL DA COMPRA) ---
      final cardQuery = await txn.query('credit_card', where: 'id = ?', whereArgs: [trans.creditCardId]);
      if (cardQuery.isNotEmpty) {
        double currentLimit = (cardQuery.first['limit_value'] as num).toDouble();
        double adjustment = trans.type == 'saida' ? -trans.value : trans.value;
        await txn.update('credit_card', {'limit_value': currentLimit + adjustment}, where: 'id = ?', whereArgs: [trans.creditCardId]);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getInvoiceTransactions(int cardId, String yearMonth) async {
    final db = await instance.database;
    return await db.query(
      'credit_transactions',
      where: "credit_card_id = ? AND date LIKE ?",
      whereArgs: [cardId, '$yearMonth-%'],
      orderBy: 'date DESC',
    );
  }

  // --- CORREÇÃO: Calcula a fatura subtraindo estornos/pagamentos (entradas) de compras (saídas) ---
  Future<double> getInvoiceTotal(int cardId, String yearMonth) async {
    final db = await instance.database;
    final purchases = await db.rawQuery(
        "SELECT SUM(value) as total FROM credit_transactions WHERE credit_card_id = ? AND type = 'saida' AND date LIKE ?",
        [cardId, '$yearMonth-%']
    );
    final payments = await db.rawQuery(
        "SELECT SUM(value) as total FROM credit_transactions WHERE credit_card_id = ? AND type = 'entrada' AND date LIKE ?",
        [cardId, '$yearMonth-%']
    );
    double totalPurchases = (purchases.first['total'] as num?)?.toDouble() ?? 0.0;
    double totalPayments = (payments.first['total'] as num?)?.toDouble() ?? 0.0;
    return totalPurchases - totalPayments;
  }

  Future<void> payInvoice(int cardId, int accountId, double amount, String cardName, String paymentDate) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final nowTime = DateFormat('HH:mm:ss').format(DateTime.now());

      await txn.insert('account_transactions', {
        'type': 'saida',
        'description': 'Pagamento Fatura - $cardName',
        'value': amount,
        'category': 'Cartão de Crédito',
        'date': paymentDate, // Usa a data selecionada
        'time': nowTime,
        'accounts_id': accountId,
      });

      final accountQuery = await txn.query('accounts', where: 'id = ?', whereArgs: [accountId]);
      if (accountQuery.isNotEmpty) {
        double currentBalance = (accountQuery.first['balance'] as num).toDouble();
        await txn.update('accounts', {'balance': currentBalance - amount}, where: 'id = ?', whereArgs: [accountId]);
      }

      await txn.insert('credit_transactions', {
        'type': 'entrada',
        'description': 'Pagamento de Fatura',
        'value': amount,
        'category': 'Pagamento',
        'date': paymentDate, // Usa a data selecionada
        'installment': 1,
        'credit_card_id': cardId,
      });

      final cardQuery = await txn.query('credit_card', where: 'id = ?', whereArgs: [cardId]);
      if (cardQuery.isNotEmpty) {
        double currentLimit = (cardQuery.first['limit_value'] as num).toDouble();
        await txn.update('credit_card', {'limit_value': currentLimit + amount}, where: 'id = ?', whereArgs: [cardId]);
      }
    });
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

  // --- EXCLUSÃO DE TRANSAÇÃO (Estorna o saldo da conta) ---
  Future<void> deleteTransaction(AccountTransaction trans) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // 1. Remove a transação do histórico
      await txn.delete('account_transactions', where: 'id = ?', whereArgs: [trans.id]);

      // 2. Busca o saldo da conta para estornar o valor
      final accountQuery = await txn.query('accounts', where: 'id = ?', whereArgs: [trans.accountsId]);
      if (accountQuery.isNotEmpty) {
        double currentBalance = (accountQuery.first['balance'] as num).toDouble();
        // Se era uma entrada, removemos do saldo. Se era saída, devolvemos ao saldo.
        double rollback = trans.type == 'entrada' ? -trans.value : trans.value;

        await txn.update(
          'accounts',
          {'balance': currentBalance + rollback},
          where: 'id = ?',
          whereArgs: [trans.accountsId],
        );
      }
    });
  }

  // --- EDIÇÃO DE TRANSAÇÃO (Mescla o estorno do antigo com o novo valor) ---
  Future<void> updateTransaction(AccountTransaction newTrans, AccountTransaction oldTrans) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // 1. Atualiza os dados da transação
      await txn.update('account_transactions', newTrans.toMap(), where: 'id = ?', whereArgs: [newTrans.id]);

      // 2. Desfaz o impacto do saldo antigo
      final accountQuery = await txn.query('accounts', where: 'id = ?', whereArgs: [newTrans.accountsId]);
      if (accountQuery.isNotEmpty) {
        double balance = (accountQuery.first['balance'] as num).toDouble();

        // Remove o efeito da antiga
        double oldAdjustment = oldTrans.type == 'entrada' ? -oldTrans.value : oldTrans.value;
        balance += oldAdjustment;

        // Aplica o efeito da nova
        double newAdjustment = newTrans.type == 'entrada' ? newTrans.value : -newTrans.value;
        balance += newAdjustment;

        // 3. Salva o saldo final recalculado
        await txn.update('accounts', {'balance': balance}, where: 'id = ?', whereArgs: [newTrans.accountsId]);
      }
    });
  }

  // --- EXCLUSÃO DE TRANSAÇÃO DO CARTÃO ---
  Future<void> deleteCreditTransaction(CreditTransaction trans) async {
    final db = await instance.database;
    await db.transaction((txn) async {

      // NOVO: Se for um "Pagamento de Fatura", caça a transação na conta bancária e devolve o dinheiro
      if (trans.category == 'Pagamento' && trans.description == 'Pagamento de Fatura') {
        final accTransQuery = await txn.query(
            'account_transactions',
            where: "category = 'Cartão de Crédito' AND description LIKE 'Pagamento Fatura %' AND value = ? AND date = ?",
            whereArgs: [trans.value, trans.date]
        );

        if (accTransQuery.isNotEmpty) {
          int accTransId = accTransQuery.first['id'] as int;
          int accId = accTransQuery.first['accounts_id'] as int;

          // Apaga o registro da conta corrente
          await txn.delete('account_transactions', where: 'id = ?', whereArgs: [accTransId]);

          // Restaura o saldo físico da conta bancária
          final accQuery = await txn.query('accounts', where: 'id = ?', whereArgs: [accId]);
          if (accQuery.isNotEmpty) {
            double bal = (accQuery.first['balance'] as num).toDouble();
            await txn.update('accounts', {'balance': bal + trans.value}, where: 'id = ?', whereArgs: [accId]);
          }
        }
      }

      // Lógica existente de exclusão de compras/parcelas e estorno de limite de cartão
      if (trans.currentInstallment == 1) {
        final related = await txn.query(
            'credit_transactions',
            where: 'description = ? AND credit_card_id = ? AND installment = ? AND category = ?',
            whereArgs: [trans.description, trans.creditCardId, trans.installment, trans.category]
        );

        double totalValueToRollback = 0.0;
        for (var row in related) {
          totalValueToRollback += (row['value'] as num).toDouble();
        }

        await txn.delete(
            'credit_transactions',
            where: 'description = ? AND credit_card_id = ? AND installment = ? AND category = ?',
            whereArgs: [trans.description, trans.creditCardId, trans.installment, trans.category]
        );

        final cardQuery = await txn.query('credit_card', where: 'id = ?', whereArgs: [trans.creditCardId]);
        if (cardQuery.isNotEmpty) {
          double currentLimit = (cardQuery.first['limit_value'] as num).toDouble();
          double rollback = trans.type == 'saida' ? totalValueToRollback : -totalValueToRollback;
          await txn.update('credit_card', {'limit_value': currentLimit + rollback}, where: 'id = ?', whereArgs: [trans.creditCardId]);
        }
      } else {
        await txn.delete('credit_transactions', where: 'id = ?', whereArgs: [trans.id]);
      }
    });
  }

  // --- EDIÇÃO DE TRANSAÇÃO DO CARTÃO ---
  Future<void> updateCreditTransaction(CreditTransaction newTrans, CreditTransaction oldTrans) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // 1. Busca e calcula o montante total gasto no grupo antigo
      final oldRelated = await txn.query(
          'credit_transactions',
          where: 'description = ? AND credit_card_id = ? AND installment = ? AND category = ?',
          whereArgs: [oldTrans.description, oldTrans.creditCardId, oldTrans.installment, oldTrans.category]
      );

      double totalOldValue = 0.0;
      for (var row in oldRelated) {
        totalOldValue += (row['value'] as num).toDouble();
      }

      // 2. Desfaz o impacto devolvendo o limite total antigo ao cartão de origem
      final oldCardQuery = await txn.query('credit_card', where: 'id = ?', whereArgs: [oldTrans.creditCardId]);
      if (oldCardQuery.isNotEmpty) {
        double limit = (oldCardQuery.first['limit_value'] as num).toDouble();
        limit += oldTrans.type == 'saida' ? totalOldValue : -totalOldValue;
        await txn.update('credit_card', {'limit_value': limit}, where: 'id = ?', whereArgs: [oldTrans.creditCardId]);
      }

      // 3. Remove todas as parcelas antigas vinculadas
      await txn.delete(
          'credit_transactions',
          where: 'description = ? AND credit_card_id = ? AND installment = ? AND category = ?',
          whereArgs: [oldTrans.description, oldTrans.creditCardId, oldTrans.installment, oldTrans.category]
      );

      // 4. Inserção do novo grupo recalculando a distribuição exata de centavos e novas datas
      int totalCents = (newTrans.value * 100).round();
      int baseCents = totalCents ~/ newTrans.installment;
      int remainderCents = totalCents % newTrans.installment;

      DateTime originalDate = DateTime.parse(newTrans.date);

      for (int i = 1; i <= newTrans.installment; i++) {
        double instValue = (i == 1) ? (baseCents + remainderCents) / 100.0 : baseCents / 100.0;

        int totalMonths = originalDate.month - 1 + (i - 1);
        int targetYear = originalDate.year + (totalMonths ~/ 12);
        int targetMonth = (totalMonths % 12) + 1;
        int targetDay = originalDate.day;

        int daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        if (targetDay > daysInMonth) targetDay = daysInMonth;

        String instDate = "${targetYear.toString()}-${targetMonth.toString().padLeft(2, '0')}-${targetDay.toString().padLeft(2, '0')}";

        Map<String, dynamic> map = newTrans.toMap();
        map['value'] = instValue;
        map['date'] = instDate;
        map['current_installment'] = i;
        map.remove('id');

        await txn.insert('credit_transactions', map);
      }

      // 5. Deduz o limite total atualizado do cartão final selecionado
      final newCardQuery = await txn.query('credit_card', where: 'id = ?', whereArgs: [newTrans.creditCardId]);
      if (newCardQuery.isNotEmpty) {
        double currentLimit = (newCardQuery.first['limit_value'] as num).toDouble();
        double newAdjustment = newTrans.type == 'saida' ? -newTrans.value : newTrans.value;
        await txn.update('credit_card', {'limit_value': currentLimit + newAdjustment}, where: 'id = ?', whereArgs: [newTrans.creditCardId]);
      }
    });
  }

  Future<double> getCreditTransactionGroupTotal(CreditTransaction trans) async {
    final db = await instance.database;
    final result = await db.query(
      'credit_transactions',
      columns: ['SUM(value) as total'],
      where: 'description = ? AND credit_card_id = ? AND installment = ? AND category = ?',
      whereArgs: [trans.description, trans.creditCardId, trans.installment, trans.category],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return trans.value; // Retorno de segurança
  }

  // --- BUSCA DESPESAS AGRUPADAS POR CATEGORIA (MÊS ATUAL) ---
  Future<List<Map<String, dynamic>>> getExpensesByCategory() async {
    final db = await instance.database;
    final now = DateTime.now();
    // Cria o filtro do mês atual. Ex: "2026-05%"
    final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}%";

    return await db.rawQuery('''
      SELECT category, SUM(value) as total 
      FROM account_transactions 
      WHERE type = 'saida' AND date LIKE ?
      GROUP BY category 
      ORDER BY total DESC
    ''', [monthStr]);
  }
}

