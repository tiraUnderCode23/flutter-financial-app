import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/debt_models.dart';
import '../models/expense_models.dart';
import '../models/income_models.dart';

class AdvancedDatabaseHelper {
  static final AdvancedDatabaseHelper _instance =
      AdvancedDatabaseHelper._internal();
  factory AdvancedDatabaseHelper() => _instance;
  AdvancedDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'financial_manager_he.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // טבלת שטרות
    await db.execute('''
      CREATE TABLE checks (
        id TEXT PRIMARY KEY,
        checkNumber TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        dueDate INTEGER NOT NULL,
        payeeName TEXT NOT NULL,
        bankName TEXT,
        isPaid INTEGER NOT NULL DEFAULT 0,
        description TEXT
      )
    ''');

    // טבלת הוראות קבע
    await db.execute('''
      CREATE TABLE standing_orders (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        payeeName TEXT NOT NULL,
        frequency TEXT NOT NULL,
        nextPaymentDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        isPaid INTEGER NOT NULL DEFAULT 0,
        description TEXT
      )
    ''');

    // טבלת הלוואות
    await db.execute('''
      CREATE TABLE loans (
        id TEXT PRIMARY KEY,
        originalAmount REAL NOT NULL,
        monthlyPayment REAL NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        interestRate REAL DEFAULT 0.0,
        lenderName TEXT NOT NULL,
        remainingAmount REAL DEFAULT 0.0,
        description TEXT
      )
    ''');

    // טבלת תשלומי חובות
    await db.execute('''
      CREATE TABLE debt_payments (
        id TEXT PRIMARY KEY,
        loanId TEXT,
        checkId TEXT,
        standingOrderId TEXT,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        description TEXT,
        FOREIGN KEY (loanId) REFERENCES loans (id),
        FOREIGN KEY (checkId) REFERENCES checks (id),
        FOREIGN KEY (standingOrderId) REFERENCES standing_orders (id)
      )
    ''');

    // טבלת מקורות הכנסה
    await db.execute('''
      CREATE TABLE income_sources (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // טבלת הכנסות מתקדמות
    await db.execute('''
      CREATE TABLE advanced_incomes (
        id TEXT PRIMARY KEY,
        sourceId TEXT,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        categoryId TEXT,
        paymentMethod TEXT,
        taxAmount REAL DEFAULT 0.0,
        grossAmount REAL DEFAULT 0.0,
        netAmount REAL DEFAULT 0.0,
        currency TEXT DEFAULT 'ILS',
        tags TEXT,
        attachments TEXT,
        additionalData TEXT,
        FOREIGN KEY (sourceId) REFERENCES income_sources (id)
      )
    ''');

    // טבלת פרויקטי עבודה
    await db.execute('''
      CREATE TABLE work_projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        hourlyRate REAL NOT NULL,
        hoursWorked REAL NOT NULL,
        totalAmount REAL NOT NULL,
        date INTEGER NOT NULL,
        clientName TEXT,
        description TEXT
      )
    ''');

    // טבלת ספקים
    await db.execute('''
      CREATE TABLE vendors (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        contact TEXT,
        address TEXT,
        taxId TEXT,
        notes TEXT
      )
    ''');

    // טבלת הוצאות מתקדמות
    await db.execute('''
      CREATE TABLE advanced_expenses (
        id TEXT PRIMARY KEY,
        vendorId TEXT,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        paymentMethod TEXT,
        currency TEXT DEFAULT 'ILS',
        tags TEXT,
        receiptNumber TEXT,
        vatAmount REAL DEFAULT 0.0,
        totalAmount REAL NOT NULL,
        attachments TEXT,
        location TEXT,
        additionalData TEXT,
        FOREIGN KEY (vendorId) REFERENCES vendors (id)
      )
    ''');

    // טבלת פריטי קבלה
    await db.execute('''
      CREATE TABLE receipt_items (
        id TEXT PRIMARY KEY,
        expenseId TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity REAL DEFAULT 1.0,
        unit TEXT DEFAULT 'יח',
        category TEXT DEFAULT 'אחר',
        FOREIGN KEY (expenseId) REFERENCES advanced_expenses (id)
      )
    ''');

    // אינדקסים לביצועים טובים יותר
    await db.execute('CREATE INDEX idx_checks_date ON checks(date)');
    await db.execute(
      'CREATE INDEX idx_loans_dates ON loans(startDate, endDate)',
    );
    await db.execute('CREATE INDEX idx_incomes_date ON advanced_incomes(date)');
    await db.execute(
      'CREATE INDEX idx_expenses_date ON advanced_expenses(date)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_vendor ON advanced_expenses(vendorId)',
    );
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // לעדכונים עתידיים של מסד הנתונים
  }

  // פונקציות שטרות
  Future<void> insertCheck(Check check) async {
    final db = await database;
    await db.insert('checks', check.toMap());
  }

  Future<List<Check>> getChecks() async {
    final db = await database;
    final maps = await db.query('checks', orderBy: 'dueDate ASC');
    return maps.map((map) => Check.fromMap(map)).toList();
  }

  Future<void> updateCheck(Check check) async {
    final db = await database;
    await db.update(
      'checks',
      check.toMap(),
      where: 'id = ?',
      whereArgs: [check.id],
    );
  }

  Future<void> deleteCheck(String id) async {
    final db = await database;
    await db.delete('checks', where: 'id = ?', whereArgs: [id]);
  }

  // פונקציות הוראות קבע
  Future<void> insertStandingOrder(StandingOrder order) async {
    final db = await database;
    await db.insert('standing_orders', order.toMap());
  }

  Future<List<StandingOrder>> getStandingOrders() async {
    final db = await database;
    final maps = await db.query(
      'standing_orders',
      orderBy: 'nextPaymentDate ASC',
    );
    return maps.map((map) => StandingOrder.fromMap(map)).toList();
  }

  Future<void> updateStandingOrder(StandingOrder order) async {
    final db = await database;
    await db.update(
      'standing_orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<void> deleteStandingOrder(String id) async {
    final db = await database;
    await db.delete('standing_orders', where: 'id = ?', whereArgs: [id]);
  }

  // פונקציות הלוואות
  Future<void> insertLoan(Loan loan) async {
    final db = await database;
    await db.insert('loans', loan.toMap());
  }

  Future<List<Loan>> getLoans() async {
    final db = await database;
    final maps = await db.query('loans', orderBy: 'startDate DESC');
    return maps.map((map) => Loan.fromMap(map)).toList();
  }

  Future<void> updateLoan(Loan loan) async {
    final db = await database;
    await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<void> deleteLoan(String id) async {
    final db = await database;
    await db.delete('loans', where: 'id = ?', whereArgs: [id]);
  }

  // פונקציות תשלומי חובות
  Future<void> insertDebtPayment(DebtPayment payment) async {
    final db = await database;
    await db.insert('debt_payments', payment.toMap());
  }

  Future<List<DebtPayment>> getDebtPayments() async {
    final db = await database;
    final maps = await db.query('debt_payments', orderBy: 'date DESC');
    return maps.map((map) => DebtPayment.fromMap(map)).toList();
  }

  // פונקציות ספקים
  Future<void> insertVendor(Vendor vendor) async {
    final db = await database;
    await db.insert('vendors', {
      'id': vendor.name, // Using name as ID for now
      'name': vendor.name,
      'contact': vendor.phone ?? '',
      'address': vendor.address ?? '',
      'taxId': '',
      'notes': vendor.category ?? '',
    });
  }

  Future<List<Vendor>> getVendors() async {
    final db = await database;
    final maps = await db.query('vendors', orderBy: 'name ASC');
    return maps.map((map) => Vendor(
      name: map['name'] as String,
      address: map['address'] as String?,
      phone: map['contact'] as String?,
      category: map['notes'] as String?,
    )).toList();
  }

  Future<Vendor?> getVendorByName(String name) async {
    final db = await database;
    final maps = await db.query(
      'vendors',
      where: 'name = ?',
      whereArgs: [name],
    );
    return maps.isNotEmpty ? Vendor(
      name: maps.first['name'] as String,
      address: maps.first['address'] as String?,
      phone: maps.first['contact'] as String?,
      category: maps.first['notes'] as String?,
    ) : null;
  }

  // פונקציות הכנסות מתקדמות
  Future<void> insertAdvancedIncome(AdvancedIncome income) async {
    final db = await database;
    await db.insert('advanced_incomes', {
      ...income.toMap(),
      'additionalData': income.additionalData.isNotEmpty
          ? income.toJson()
          : null,
    });
  }

  Future<List<AdvancedIncome>> getAdvancedIncomes() async {
    final db = await database;
    final maps = await db.query('advanced_incomes', orderBy: 'date DESC');
    return maps.map((map) => AdvancedIncome.fromMap(map)).toList();
  }

  // עדכון הכנסה מתקדמת
  Future<void> updateAdvancedIncome(AdvancedIncome income) async {
    final db = await database;
    await db.update(
      'advanced_incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  // מחיקת הכנסה מתקדמת
  Future<void> deleteAdvancedIncome(String incomeId) async {
    final db = await database;
    await db.delete('advanced_incomes', where: 'id = ?', whereArgs: [incomeId]);
  }

  // פונקציות הוצאות מתקדמות
  Future<void> insertAdvancedExpense(AdvancedExpense expense) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('advanced_expenses', expense.toMap());

      if (expense.receiptItems?.isNotEmpty == true) {
        for (final item in expense.receiptItems!) {
          await txn.insert('receipt_items', {
            'id': item.id,
            'expenseId': expense.id,
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'unit': item.unit,
            'category': item.category,
          });
        }
      }
    });
  }

  Future<List<AdvancedExpense>> getAdvancedExpenses() async {
    final db = await database;
    final maps = await db.query('advanced_expenses', orderBy: 'date DESC');
    List<AdvancedExpense> expenses = [];

    for (final map in maps) {
      final expense = AdvancedExpense.fromMap(map);

      // טעינת פריטי הקבלה
      final itemMaps = await db.query(
        'receipt_items',
        where: 'expenseId = ?',
        whereArgs: [expense.id],
      );

      final items = itemMaps
          .map(
            (itemMap) => ReceiptItem(
              id: itemMap['id'] as String,
              name: itemMap['name'] as String,
              unitPrice: (itemMap['price'] as num).toDouble(),
              quantity: (itemMap['quantity'] as num).toDouble(),
              unit: itemMap['unit'] as String,
              category: itemMap['category'] as String,
            ),
          )
          .toList();

      expenses.add(expense.copyWith(receiptItems: items));
    }

    return expenses;
  }

  // עדכון הוצאה מתקדמת
  Future<void> updateAdvancedExpense(AdvancedExpense expense) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'advanced_expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );

      // עדכון פריטי הקבלה
      await txn.delete(
        'receipt_items',
        where: 'expenseId = ?',
        whereArgs: [expense.id],
      );

      if (expense.receiptItems?.isNotEmpty == true) {
        for (final item in expense.receiptItems!) {
          await txn.insert('receipt_items', {
            'id': item.id,
            'expenseId': expense.id,
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'unit': item.unit,
            'category': item.category,
          });
        }
      }
    });
  }

  // מחיקת הוצאה מתקדמת
  Future<void> deleteAdvancedExpense(String expenseId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'receipt_items',
        where: 'expenseId = ?',
        whereArgs: [expenseId],
      );
      await txn.delete(
        'advanced_expenses',
        where: 'id = ?',
        whereArgs: [expenseId],
      );
    });
  }

  // פונקציות סטטיסטיקות
  Future<Map<String, double>> getExpensesByCategory() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM advanced_expenses
      GROUP BY category
      ORDER BY total DESC
    ''');

    return Map.fromEntries(
      maps.map(
        (map) => MapEntry(
          map['category'] as String,
          (map['total'] as num).toDouble(),
        ),
      ),
    );
  }

  Future<Map<String, double>> getIncomesByType() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM advanced_incomes
      GROUP BY type
      ORDER BY total DESC
    ''');

    return Map.fromEntries(
      maps.map(
        (map) =>
            MapEntry(map['type'] as String, (map['total'] as num).toDouble()),
      ),
    );
  }

  Future<double> getTotalDebt() async {
    final db = await database;

    // סכום כל השטרות שלא שולמו
    final checksResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM checks WHERE isPaid = 0',
    );
    final checksTotal =
        (checksResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // סכום כל ההלוואות הפעילות
    final loansResult = await db.rawQuery(
      'SELECT SUM(remainingAmount) as total FROM loans WHERE endDate > ?',
      [DateTime.now().millisecondsSinceEpoch],
    );
    final loansTotal = (loansResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return checksTotal + loansTotal;
  }

  // ניקוי מסד הנתונים
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('checks');
      await txn.delete('standing_orders');
      await txn.delete('loans');
      await txn.delete('debt_payments');
      await txn.delete('income_sources');
      await txn.delete('advanced_incomes');
      await txn.delete('work_projects');
      await txn.delete('vendors');
      await txn.delete('advanced_expenses');
      await txn.delete('receipt_items');
    });
  }

  // סגירת מסד הנתונים
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // יצירת נסיון גיבוי
  Future<Map<String, dynamic>> createBackup() async {
    final db = await database;

    final backup = <String, dynamic>{};

    // גיבוי לשיקים
    backup['checks'] = await db.query('checks');

    // גיבוי להוראות קבע
    backup['standing_orders'] = await db.query('standing_orders');

    // גיבוי להלוואות
    backup['loans'] = await db.query('loans');

    // גיבוי לתשלומי חובות
    backup['debt_payments'] = await db.query('debt_payments');

    // גיבוי למקורות הכנסה
    backup['income_sources'] = await db.query('income_sources');

    // גיבוי להכנסות מתקדמות
    backup['advanced_incomes'] = await db.query('advanced_incomes');

    // גיבוי לפרויקטי עבודה
    backup['work_projects'] = await db.query('work_projects');

    // גיבוי לספקים
    backup['vendors'] = await db.query('vendors');

    // גיבוי להוצאות מתקדמות
    backup['advanced_expenses'] = await db.query('advanced_expenses');

    // גיבוי לפריטי קבלה
    backup['receipt_items'] = await db.query('receipt_items');

    backup['created_at'] = DateTime.now().toIso8601String();
    backup['version'] = '1.0';

    return backup;
  }

  // שחזור נסיון גיבוי
  Future<bool> restoreBackup(Map<String, dynamic> backup) async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        // מחיקת הנתונים הנוכחיים
        await txn.delete('checks');
        await txn.delete('standing_orders');
        await txn.delete('loans');
        await txn.delete('debt_payments');
        await txn.delete('income_sources');
        await txn.delete('advanced_incomes');
        await txn.delete('work_projects');
        await txn.delete('vendors');
        await txn.delete('advanced_expenses');
        await txn.delete('receipt_items');

        // שחזור הנתונים מהגיבוי
        if (backup.containsKey('checks')) {
          for (var item in backup['checks'] as List) {
            await txn.insert('checks', item as Map<String, dynamic>);
          }
        }

        if (backup.containsKey('standing_orders')) {
          for (var item in backup['standing_orders'] as List) {
            await txn.insert('standing_orders', item as Map<String, dynamic>);
          }
        }

        if (backup.containsKey('loans')) {
          for (var item in backup['loans'] as List) {
            await txn.insert('loans', item as Map<String, dynamic>);
          }
        }

        if (backup.containsKey('debt_payments')) {
          for (var item in backup['debt_payments'] as List) {
            await txn.insert('debt_payments', item as Map<String, dynamic>);
          }
        }

        if (backup.containsKey('income_sources')) {
          for (var item in backup['income_sources'] as List) {
            await txn.insert('income_sources', item as Map<String, dynamic>);
          }
        }

        if (backup.containsKey('advanced_incomes')) {
          for (var item in backup['advanced_incomes'] as List) {
            await txn.insert('advanced_incomes', item as Map<String, dynamic>);
          }
        }

        if (backup.containsKey('work_projects')) {
          for (var item in backup['work_projects'] as List) {
            await txn.insert('work_projects', item as Map<String, dynamic>);
          }
        }

        if (backup.containsKey('vendors')) {
          for (var item in backup['vendors'] as List) {
            await txn.insert('vendors', item as Map<String, dynamic>);
          }
        }

        if (backup.containsKey('advanced_expenses')) {
          for (var item in backup['advanced_expenses'] as List) {
            await txn.insert('advanced_expenses', item as Map<String, dynamic>);
          }
        }

        if (backup.containsKey('receipt_items')) {
          for (var item in backup['receipt_items'] as List) {
            await txn.insert('receipt_items', item as Map<String, dynamic>);
          }
        }
      });

      return true;
    } catch (e) {
      print('שגיאה בשחזור הגיבוי: $e');
      return false;
    }
  }
}
