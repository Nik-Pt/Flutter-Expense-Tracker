import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart' show join;
import '../../models/transaction.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        amount REAL,
        date INTEGER,
        category TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
      await db.execute('ALTER TABLE transactions ADD COLUMN description TEXT DEFAULT ""');

      await db.execute("UPDATE transactions SET category = 'Food Deliveries' WHERE category = 'Food'");
      await db.execute("UPDATE transactions SET category = 'Public Transit' WHERE category = 'Transport'");
      await db.execute("UPDATE transactions SET category = 'Clothing' WHERE category = 'Shopping'");
      await db.execute("UPDATE transactions SET category = 'Outings' WHERE category = 'Entertainment'");
      await db.execute("UPDATE transactions SET category = 'Utilities' WHERE category = 'Bills'");
      await db.execute("UPDATE transactions SET category = 'Pharmacy' WHERE category = 'Health'");
  }

  Future<int> create(Transaction tx) async {
    final db = await instance.database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<int> update(Transaction tx) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Transaction>> getTransactionsByMonth(DateTime month) async {
    final db = await instance.database;
    final start = DateTime(month.year, month.month, 1).millisecondsSinceEpoch;
    final nextMonthDate = (month.month == 12)
        ? DateTime(month.year + 1, 1, 1)
        : DateTime(month.year, month.month + 1, 1);
    final end = nextMonthDate.millisecondsSinceEpoch;

    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date DESC',
    );
    return result.map((json) => Transaction.fromMap(json)).toList();
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => Transaction.fromMap(json)).toList();
  }
}