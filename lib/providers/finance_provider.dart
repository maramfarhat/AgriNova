import 'package:flutter/foundation.dart';
import 'package:farm/models/financial_transaction.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TransactionData {
  final DateTime date;
  final double amount;

  TransactionData({
    required this.date,
    required this.amount,
  });
}

class FinanceProvider with ChangeNotifier {
  List<FinancialTransaction> _transactions = [];
  Database? _db;
  bool _isInitialized = false;

  List<FinancialTransaction> get transactions =>
      List.unmodifiable(_transactions);

  Future<void> initDatabase() async {
    if (_isInitialized) return;

    debugPrint('Initializing finance database...');
    try {
      final dbPath = await getDatabasesPath();
      _db = await openDatabase(
        join(dbPath, 'finance.db'),
        onCreate: (db, version) {
          debugPrint('Creating finance database tables...');
          return db.execute(
            '''CREATE TABLE IF NOT EXISTS transactions(
              id TEXT PRIMARY KEY,
              amount REAL,
              type TEXT,
              category TEXT,
              description TEXT,
              date TEXT,
              cropId TEXT
            )''',
          );
        },
        version: 1,
      );
      _isInitialized = true;
      debugPrint('Finance database initialized successfully');
      await loadTransactions();
    } catch (e) {
      debugPrint('Error initializing finance database: $e');
      rethrow;
    }
  }

  Future<void> loadTransactions() async {
    final List<Map<String, dynamic>> maps = await _db!.query('transactions');
    _transactions =
        maps.map((map) => FinancialTransaction.fromJson(map)).toList();
    notifyListeners();
  }

  Future<void> addTransaction(FinancialTransaction transaction) async {
    await _db!.insert(
      'transactions',
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await loadTransactions();
  }

  double getTotalIncome() {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenses() {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getBalance() {
    return getTotalIncome() - getTotalExpenses();
  }

  Map<String, double> getCropProfits() {
    Map<String, double> profits = {};

    for (var transaction in _transactions) {
      if (transaction.cropId != null) {
        profits[transaction.cropId!] = (profits[transaction.cropId!] ?? 0) +
            (transaction.type == TransactionType.income
                ? transaction.amount
                : -transaction.amount);
      }
    }

    return profits;
  }

  List<FinancialTransaction> getTransactionsForCrop(String cropId) {
    return _transactions.where((t) => t.cropId == cropId).toList();
  }

  Map<DateTime, List<FinancialTransaction>> getTransactionsByMonth() {
    Map<DateTime, List<FinancialTransaction>> grouped = {};

    for (var transaction in _transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        1,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }

    return grouped;
  }

  Future<void> deleteTransaction(String id) async {
    await _db!.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadTransactions();
  }

  double getRevenueByCropId(String cropId) {
    return _transactions
        .where((t) => t.cropId == cropId && t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getExpensesByCropId(String cropId) {
    return _transactions
        .where((t) => t.cropId == cropId && t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  Future<List<TransactionData>> getTransactionsByPeriod(String period) async {
    final db = _db!;
    String groupBy;
    String dateFormat;
    String dateSelect;

    switch (period) {
      case 'minute':
        dateFormat = "'%Y-%m-%d %H:%M'";
        dateSelect = "strftime('%Y-%m-%d %H:%M:00', datetime(date))";
        groupBy = dateSelect;
        break;
      case 'hour':
        dateFormat = "'%Y-%m-%d %H'";
        dateSelect = "strftime('%Y-%m-%d %H:00:00', datetime(date))";
        groupBy = dateSelect;
        break;
      case 'day':
        dateFormat = "'%Y-%m-%d'";
        dateSelect = "strftime('%Y-%m-%d 00:00:00', date)";
        groupBy = dateSelect;
        break;
      case 'week':
        dateFormat = "'%Y-%W'";
        dateSelect = "date(date, 'weekday 0', '-7 days')";
        groupBy = "strftime($dateFormat, date)";
        break;
      case 'month':
        dateFormat = "'%Y-%m'";
        dateSelect = "date(date, 'start of month')";
        groupBy = "strftime($dateFormat, date)";
        break;
      default:
        dateFormat = "'%Y-%m'";
        dateSelect = "date(date, 'start of month')";
        groupBy = "strftime($dateFormat, date)";
    }

    try {
      debugPrint('Executing query for period: $period');
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        WITH grouped_data AS (
          SELECT 
            $dateSelect as period_date,
            type,
            amount
          FROM transactions
          WHERE date >= datetime('now', '-1 month')
        )
        SELECT 
          period_date as date,
          SUM(CASE WHEN type = 'TransactionType.income' THEN amount ELSE 0 END) as income,
          SUM(CASE WHEN type = 'TransactionType.expense' THEN ABS(amount) ELSE 0 END) as expense
        FROM grouped_data
        GROUP BY period_date
        ORDER BY period_date
      ''');

      debugPrint('Query results: ${result.length} rows');
      for (var row in result) {
        debugPrint('Row: ${row.toString()}');
      }

      if (result.isEmpty) {
        debugPrint('No data found for period: $period');
        return [];
      }

      List<TransactionData> data = [];

      for (var row in result) {
        final date = DateTime.parse(row['date']);
        final income = (row['income'] as num?)?.toDouble() ?? 0.0;
        final expense = (row['expense'] as num?)?.toDouble() ?? 0.0;

        if (income > 0) {
          data.add(TransactionData(
            date: date,
            amount: income,
          ));
        }
        if (expense > 0) {
          data.add(TransactionData(
            date: date,
            amount: -expense,
          ));
        }
      }

      debugPrint('Processed ${data.length} transactions');
      return data;
    } catch (e) {
      debugPrint('Error getting transactions by period: $e');
      return [];
    }
  }
}
